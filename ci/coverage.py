#!/usr/bin/env python3
"""Cobertura por função do QML, sem parser de JavaScript.

    ci/coverage.py instrument PASTA [--all]
        Só numa cópia do repositório (PASTA sem .git): põe
        Cov.hit("<chave>") na primeira linha de cada `function nome(...) {`
        dos arquivos do escopo (tests/coverage.json) ou, com --all, de todos
        os .qml; acrescenta `import qs.cov`; cria o singleton PASTA/cov/Cov.qml;
        grava as funções em PASTA/cov/functions.json; e troca a linha
        "// @cov-dump" do tests/runner.qml por Cov.dump().

    ci/coverage.py report PASTA LOG... [--gate] [--md ARQUIVO]
        Cruza as funções com as chamadas (linhas "COV <chave> <n>" dos LOGs) e
        imprime o relatório por arquivo. Com --gate, só o escopo que bloqueia,
        e falha se uma função dele não foi chamada, se o tests/coverage.json
        cita função que não existe, se o escopo tem 0 funções ou se os LOGs não
        têm nenhuma linha COV. Sem --gate, é informativo: só avisa. Com --md,
        grava também o relatório em Markdown (para o resumo do job).

O tests/coverage.json é conferido (as quatro chaves, com os tipos certos);
fora do formato, o instrument e o report --gate falham dizendo o quê.

A chave é "<arquivo>:<nome>", com os objetos em volta quando a função não é
da raiz ("core/panels/Panels.qml:IpcHandler.open") e #2, #3… quando o mesmo
nome se repete no mesmo lugar. Só o padrão `function nome(...) {` numa linha
é instrumentado; outro formato é erro, para não contar errado.
"""

import argparse
import json
import re
import sys
from pathlib import Path

FUNC = re.compile(r"^(\s*)function\s+(\w+)\s*\(.*\)\s*(?::\s*[\w.<>]+\s*)?\{\s*$")
ANY_FUNC = re.compile(r"^\s*function\s+\w+")
COMPONENT = re.compile(r"^\s*component\s+(\w+)\s*:")
OPENER = re.compile(r"([A-Z]\w*)\s*\{\s*$")
IMPORT = re.compile(r"^import\s")
# A linha COV vem do Cov.dump(): a primeira com o prefixo do qs ("  INFO qml: ",
# talvez com data antes, num log da fumaça), as outras sozinhas; ou da saída do
# `qs ipc call cov dump`, sem prefixo. Ancorada no início (ou logo depois do
# "qml: ") e no fim, para um "COV x 1" citado no meio de outra mensagem (um
# FAIL, por exemplo) não contar como chamada.
HIT = re.compile(r"^(?:[^\n]*? qml: )?COV (\S+) (\d+)[ \t]*$", re.M)
DUMP_MARK = "// @cov-dump"

COV_QML = """pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Contador de cobertura: criado pelo ci/coverage.py só na cópia instrumentada.
Singleton {
    id: root

    property var hits: ({})

    function hit(key: string): void {
        hits[key] = (hits[key] ?? 0) + 1;
    }

    function lines(): string {
        return Object.keys(hits).sort().map(k => `COV ${k} ${hits[k]}`).join("\\n");
    }

    function dump(): void {
        console.info(lines());
    }

    IpcHandler {
        target: "cov"

        function dump(): string {
            return root.lines();
        }
    }
}
"""


def parse_functions(rel, text):
    """Funções de um .qml ([{key, name, line, indent}]) e os erros (funções
    fora do padrão). O objeto em volta sai da indentação."""
    found, errors, stack, seen = [], [], [], {}
    for number, line in enumerate(text.split("\n"), 1):
        # Linha vazia ou comentário não abre nem fecha objeto, qualquer que seja
        # a indentação.
        if not line.strip() or line.lstrip().startswith(("//", "/*", "* ", "*/")):
            continue
        indent = len(line) - len(line.lstrip(" "))
        while stack and stack[-1][0] >= indent:
            stack.pop()
        match = FUNC.match(line)
        if ANY_FUNC.match(line) and not match:
            errors.append(
                f'{rel}:{number}: função fora do padrão "function nome(...) {{" numa linha só; '
                "a cobertura não consegue instrumentar"
            )
            continue
        if match:
            name = match.group(2)
            key = f"{rel}:{'.'.join([n for _, n in stack[1:]] + [name])}"
            seen[key] = seen.get(key, 0) + 1
            if seen[key] > 1:
                key = f"{key}#{seen[key]}"
            found.append({"key": key, "name": name, "line": number, "indent": indent})
            stack.append((indent, name))
            continue
        component = COMPONENT.match(line)
        opener = OPENER.search(line)
        if component:
            stack.append((indent, component.group(1)))
        elif opener:
            stack.append((indent, opener.group(1)))
    return found, errors


def instrument_text(rel, text, hits=True, runner=False):
    """O texto instrumentado, as funções achadas e os erros."""
    found, errors = parse_functions(rel, text) if hits else ([], [])
    lines = text.split("\n")
    for f in reversed(found):
        lines.insert(f["line"], " " * (f["indent"] + 4) + f'Cov.hit("{f["key"]}");')
    if runner:
        marks = [i for i, line in enumerate(lines) if line.strip() == DUMP_MARK]
        if not marks:
            errors.append(f"{rel}: falta a linha {DUMP_MARK}")
        for i in marks:
            lines[i] = lines[i].replace(DUMP_MARK, "Cov.dump();")
    if found or runner:
        imports = [i for i, line in enumerate(lines) if IMPORT.match(line)]
        lines.insert(imports[-1] + 1 if imports else 0, "import qs.cov")
    return "\n".join(lines), found, errors


class ScopeError(Exception):
    """O tests/coverage.json falta ou está fora do formato."""


SCOPE_KEYS = {"escopo": str, "fora": dict, "serviços": dict, "exceções": dict}


def load_scope(folder):
    """O tests/coverage.json da cópia, conferido: um formato errado daria um
    escopo diferente do pretendido sem ninguém ver."""
    path = folder / "tests" / "coverage.json"
    try:
        scope = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise ScopeError("falta o tests/coverage.json (o escopo da cobertura)") from None
    except json.JSONDecodeError as error:
        raise ScopeError(f"tests/coverage.json: JSON inválido: {error}") from None
    if not isinstance(scope, dict):
        raise ScopeError("tests/coverage.json: esperado um objeto")
    for key, kind in SCOPE_KEYS.items():
        if key not in scope:
            raise ScopeError(f'tests/coverage.json: falta a chave "{key}"')
        if not isinstance(scope[key], kind):
            raise ScopeError(f'tests/coverage.json: "{key}" precisa ser {"um texto" if kind is str else "um objeto"}')
    if not scope["escopo"].endswith("/"):
        raise ScopeError('tests/coverage.json: "escopo" é uma pasta, terminada em / (ex.: "core/")')
    for item, reason in scope["fora"].items():
        if not item.endswith("/"):
            raise ScopeError(f'tests/coverage.json: "fora" → {item} é uma pasta e termina em / (ex.: "core/widgets/")')
        if not isinstance(reason, str) or not reason.strip():
            raise ScopeError(f'tests/coverage.json: "fora" → {item} precisa de um motivo')
    for rel, names in scope["serviços"].items():
        if not isinstance(names, list) or not all(isinstance(n, str) for n in names):
            raise ScopeError(f'tests/coverage.json: "serviços" → {rel} precisa ser uma lista de nomes de função')
    return scope


def in_core(rel, scope):
    return rel.startswith(scope["escopo"]) and not any(rel.startswith(p) for p in scope["fora"])


def qml_files(folder):
    """Os .qml da cópia, menos o próprio Cov e os testes."""
    files = [p.relative_to(folder).as_posix() for p in sorted(folder.rglob("*.qml"))]
    return [f for f in files if not f.startswith(("cov/", "tests/"))]


def blocking(functions, scope):
    """Chaves do escopo que bloqueia e os erros do tests/coverage.json."""
    names = {}
    for f in functions:
        rel, name = f["key"].split(":", 1)
        names.setdefault(rel, set()).add(name)
    errors = []
    wanted = {f["key"] for f in functions if in_core(f["key"].split(":", 1)[0], scope)}
    for rel, listed in scope["serviços"].items():
        for name in listed:
            if name in names.get(rel, set()):
                wanted.add(f"{rel}:{name}")
            else:
                errors.append(f"tests/coverage.json: {rel}:{name} não existe (a função mudou de nome ou saiu?)")
    for key, reason in scope["exceções"].items():
        if key not in wanted:
            errors.append(f"tests/coverage.json: a exceção {key} não corresponde a nenhuma função do escopo")
        elif not str(reason).strip():
            errors.append(f"tests/coverage.json: a exceção {key} precisa de um motivo")
        wanted.discard(key)
    return wanted, errors


def instrument(folder, everything):
    if (folder / ".git").exists():
        print("ERRO: instrumente só uma cópia do repositório, nunca o próprio", file=sys.stderr)
        return 1
    try:
        scope = load_scope(folder)
    except ScopeError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1
    files = qml_files(folder)
    orphans = [p for p in scope["fora"] if not any(f.startswith(p) for f in files)]
    if orphans:
        for item in orphans:
            message = f'tests/coverage.json: "fora" → {item} não cobre nenhum .qml (a pasta mudou de nome ou saiu?)'
            print(f"ERRO: {message}", file=sys.stderr)
        return 1
    if not everything:
        files = [f for f in files if in_core(f, scope) or f in scope["serviços"]]
    found, errors = [], []
    for rel in files:
        path = folder / rel
        text, funcs, errs = instrument_text(rel, path.read_text(encoding="utf-8"))
        path.write_text(text, encoding="utf-8")
        found += funcs
        errors += errs
    runner = folder / "tests" / "runner.qml"
    if runner.exists():
        text, _, errs = instrument_text("tests/runner.qml", runner.read_text(encoding="utf-8"), hits=False, runner=True)
        runner.write_text(text, encoding="utf-8")
        errors += errs
    (folder / "cov").mkdir(exist_ok=True)
    (folder / "cov" / "Cov.qml").write_text(COV_QML, encoding="utf-8")
    (folder / "cov" / "functions.json").write_text(json.dumps(found, indent=1), encoding="utf-8")
    for error in errors:
        print(f"ERRO: {error}", file=sys.stderr)
    print(f"cobertura: {len(found)} funções instrumentadas em {len(files)} arquivos")
    return 1 if errors else 0


def read_hits(paths):
    hits = {}
    for path in paths:
        for key, count in HIT.findall(Path(path).read_text(encoding="utf-8", errors="replace")):
            hits[key] = hits.get(key, 0) + int(count)
    return hits


def report(folder, logs, gate, md):
    listing = folder / "cov" / "functions.json"
    if not listing.exists():
        print(f"ERRO: falta {listing}: rode o `ci/coverage.py instrument` nessa pasta antes")
        return 1
    functions = json.loads(listing.read_text(encoding="utf-8"))
    hits = read_hits(logs)
    keys, errors = [f["key"] for f in functions], []
    if gate:
        try:
            wanted, errors = blocking(functions, load_scope(folder))
        except ScopeError as error:
            print(f"ERRO: {error}")
            return 1
        keys = [k for k in keys if k in wanted]
    files = {}
    for key in keys:
        rel, name = key.split(":", 1)
        files.setdefault(rel, []).append((name, hits.get(key, 0) > 0))
    total = len(keys)
    covered = sum(ok for items in files.values() for _, ok in items)
    percent = 100.0 if total == 0 else round(100 * covered / total, 1)
    title = "Cobertura do escopo que bloqueia" if gate else "Cobertura de todas as funções (informativa)"
    print(f"{title}: {covered}/{total} ({percent}%)")
    # Um escopo vazio ou um log sem COV daria 100% sem medir nada.
    if not hits:
        message = "nenhuma linha COV nos logs: o Cov.dump() não rodou ou a instrumentação não pegou"
        if gate:
            errors.append(message)
        else:
            print(f"AVISO: {message}")
    if gate and total == 0:
        errors.append("o escopo que bloqueia tem 0 funções: confira tests/coverage.json e a instrumentação")
    rows = []
    for rel in sorted(files):
        items = files[rel]
        missing = [name for name, ok in items if not ok]
        print(f"  {rel}: {len(items) - len(missing)}/{len(items)}")
        for name in missing:
            print(f"    - sem chamada: {name}")
        rows.append(f"| {rel} | {len(items) - len(missing)}/{len(items)} | {', '.join(missing)} |")
    for error in errors:
        print(f"ERRO: {error}")
    if md:
        table = "| Arquivo | Cobertas | Sem chamada |\n| --- | --- | --- |\n" + "\n".join(rows) + "\n"
        problems = "".join(f"- {error}\n" for error in errors)
        problems = f"\n**Erros:**\n\n{problems}" if problems else ""
        Path(md).write_text(
            f"## {title}\n\n{covered}/{total} funções ({percent}%).\n\n{table}{problems}", encoding="utf-8"
        )
    if gate and (errors or covered < total):
        if covered < total:
            print("ERRO: toda função do escopo de tests/coverage.json precisa ser chamada por um teste")
        return 1
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description="Cobertura por função do QML.")
    sub = parser.add_subparsers(dest="command", required=True)
    ins = sub.add_parser("instrument")
    ins.add_argument("folder", type=Path)
    ins.add_argument("--all", action="store_true")
    rep = sub.add_parser("report")
    rep.add_argument("folder", type=Path)
    rep.add_argument("logs", nargs="+")
    rep.add_argument("--gate", action="store_true")
    rep.add_argument("--md", type=Path)
    args = parser.parse_args(argv)
    if args.command == "instrument":
        return instrument(args.folder, args.all)
    return report(args.folder, args.logs, args.gate, args.md)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
