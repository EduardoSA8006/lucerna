#!/usr/bin/env python3
"""Confere os logs da fumaça: toda linha de aviso ou erro precisa bater com um
padrão de ci/tolerated.txt. Uso: ci/logcheck.py TOLERADOS LOG...

No arquivo de tolerados, cada bloco (linhas seguidas, separadas por linha em
branco) que tem padrões começa com um ou mais comentários (#) com o motivo; os
padrões são expressões regulares do Python, e cada um precisa bater com a LINHA
INTEIRA (depois de tirar código ANSI e cortar os espaços das pontas) — inclusive
o nível (WARN/ERROR/...) e o texto exato medido. Nada de padrão parcial: um
padrão que batesse só com um pedaço da linha poderia engolir um erro real
emendado nela por outro motivo."""

import re
import sys
from pathlib import Path

# Linha "problema": tem palavra de nível (WARN/ERROR/...), ou um "XyzError:" de
# JS/QML sem nível nenhum (ex.: "TypeError:" isolado do scene graph), ou uma
# referência a arquivo.qml[linha ou arquivo.qml:linha (mensagens do qmllint e
# do Quickshell que não usam palavra de nível).
PROBLEM = re.compile(r"\b(WARN|WARNING|ERROR|CRITICAL|FATAL)\b|\w+Error:|\.qml[\[:]\d", re.I)

# Nunca tolerado, mesmo que algum padrão de ci/tolerated.txt bata com a linha
# inteira: reforço contra um padrão largo (ou uma anotação errada) engolir um
# TypeError/ReferenceError/SyntaxError/RangeError ou uma referência a
# arquivo.qml:NN emendada na mesma linha de um aviso de ambiente.
NEVER_TOLERATE = re.compile(r"\b\w*(?:Type|Reference|Syntax|Range)Error\b|\.qml[\[:]\d")

ANSI = re.compile(r"\x1b\[[0-9;]*m")


def load_tolerated(text):
    """Os padrões e os erros de formato do arquivo de tolerados."""
    patterns, errors = [], []
    for block in re.split(r"\n\s*\n", text):
        lines = [line for line in block.split("\n") if line.strip()]
        reasons = [line for line in lines if line.lstrip().startswith("#")]
        rules = [line for line in lines if not line.lstrip().startswith("#")]
        if rules and not reasons:
            errors.append(f"padrão sem motivo: {rules[0]}")
        for rule in rules:
            try:
                patterns.append(re.compile(rule))
            except re.error as e:
                errors.append(f"padrão inválido ({e}): {rule}")
    return patterns, errors


def problems(text, patterns):
    """(linha, texto) de cada aviso ou erro que nenhum padrão tolera.

    Um padrão só tolera quando bate com a linha inteira (fullmatch); e mesmo
    batendo, uma linha com sinal de erro real (NEVER_TOLERATE) nunca é
    tolerada."""
    out = []
    for number, raw in enumerate(text.split("\n"), 1):
        line = ANSI.sub("", raw).strip()
        if not line or not PROBLEM.search(line):
            continue
        tolerada = any(p.fullmatch(line) for p in patterns) and not NEVER_TOLERATE.search(line)
        if not tolerada:
            out.append((number, line))
    return out


def main(argv):
    if len(argv) < 2:
        print("uso: ci/logcheck.py TOLERADOS LOG...", file=sys.stderr)
        return 2
    patterns, errors = load_tolerated(Path(argv[0]).read_text(encoding="utf-8"))
    for error in errors:
        print(f"{argv[0]}: {error}")
    found = 0
    for path in argv[1:]:
        for number, line in problems(Path(path).read_text(encoding="utf-8", errors="replace"), patterns):
            print(f"{path}:{number}: {line}")
            found += 1
    print(f"logs: {found} aviso(s) ou erro(s) fora do {argv[0]}" if found else "logs: só avisos tolerados")
    return 1 if errors or found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
