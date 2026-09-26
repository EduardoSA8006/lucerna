#!/usr/bin/env python3
"""Regras do projeto que o qmllint não vê. Cada violação sai como
"arquivo:linha: [regra] mensagem"; com alguma, o script termina com 1.

    ci/rules.py              todas as regras
    ci/rules.py camadas ...  só as dadas

Só a biblioteca padrão do Python.
"""

import fnmatch
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Pastas que nunca entram, além do que o .gitignore ignora.
SKIP_DIRS = {".git", "ci-out", "__pycache__", ".ruff_cache"}


def gitignore_patterns(root):
    path = root / ".gitignore"
    if not path.exists():
        return []
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines()]
    return [line for line in lines if line and not line.startswith("#")]


def ignored(rel, patterns, is_dir):
    for pattern in patterns:
        if pattern.endswith("/"):
            if is_dir and fnmatch.fnmatch(rel.name, pattern[:-1]):
                return True
        elif fnmatch.fnmatch(rel.name, pattern) or fnmatch.fnmatch(rel.as_posix(), pattern):
            return True
    return False


def repo_files(root):
    """Arquivos do repositório (caminhos relativos), sem o que o .gitignore ignora."""
    patterns = gitignore_patterns(root)
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = Path(dirpath).relative_to(root)
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS and not ignored(rel_dir / d, patterns, True))
        for name in sorted(filenames):
            rel = rel_dir / name
            if not ignored(rel, patterns, False):
                files.append(rel)
    return files


IMPORT_QS = re.compile(r"^\s*import\s+qs\.([\w.]+)")


def check_layers(root):
    """features/*/ui não importa qs.services; uma feature não importa outra;
    core/ não importa qs.features nem qs.services."""
    out = []
    for rel in repo_files(root):
        if rel.suffix != ".qml":
            continue
        where = rel.as_posix()
        parts = rel.parts
        lines = (root / rel).read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, 1):
            match = IMPORT_QS.match(line)
            if not match:
                continue
            module = match.group(1).split(".")
            if parts[0] == "core" and module[0] in ("features", "services"):
                out.append((where, number, f"o core não pode importar qs.{module[0]}: ele só depende do Quickshell"))
            if parts[0] == "features" and len(parts) > 2:
                feature = parts[1]
                if module[0] == "features" and len(module) > 1 and module[1] != feature:
                    out.append((
                        where,
                        number,
                        f'a feature "{feature}" não pode importar outra feature (qs.features.{module[1]}): '
                        "a conversa passa pelo core ou pelos services",
                    ))
                if parts[2] == "ui" and module[0] == "services":
                    out.append((
                        where,
                        number,
                        f'a ui da feature "{feature}" não pode importar qs.services: use o state da própria feature',
                    ))
    return out


RULES = {
    "camadas": check_layers,
}


def write_summary(violations):
    out = os.environ.get("CI_OUT")
    if not out:
        return
    Path(out).mkdir(parents=True, exist_ok=True)
    with open(Path(out) / "summary.md", "a", encoding="utf-8") as f:
        f.write("## Regras\n\n")
        if not violations:
            f.write("Nenhuma violação.\n")
        for path, line, msg in violations:
            f.write(f"- `{path}:{line}`: {msg}\n")


def main(argv):
    names = argv or list(RULES)
    unknown = [n for n in names if n not in RULES]
    if unknown:
        print(f"regra desconhecida: {', '.join(unknown)} (use {', '.join(RULES)})", file=sys.stderr)
        return 2
    violations = []
    for name in names:
        violations += [(path, line, f"[{name}] {msg}") for path, line, msg in RULES[name](ROOT)]
    violations.sort()
    for path, line, msg in violations:
        print(f"{path}:{line}: {msg}")
    print(f"regras: {len(violations)} violação(ões)" if violations else "regras: nenhuma violação")
    write_summary(violations)
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
