#!/usr/bin/env bash
# Testes de unidade: copia o repositório para uma pasta temporária (copy_repo,
# do ci/lib.sh), instrumenta a cobertura nessa cópia (ci/coverage.py), põe o
# tests/runner.qml e os testes ao lado do shell.qml (para os imports qs.*
# resolverem) e roda no qs. Passa só com código 0, a linha
# "RESULT passed=N failed=0", com N > 0, para cada tests/<nome>.test.js, o
# import "<nome>.test.js" as <Módulo> no runner, o item ["<nome>", <Módulo>] em
# suites e uma linha "SUITE <nome> casos=N" (N > 0) na saída, e 100% das
# funções do escopo de tests/coverage.json chamadas. Saída em $CI_OUT: unit.log
# (a saída do qs, sem cores), coverage.txt e coverage.md (o relatório da
# cobertura) e summary.md.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=ci/lib.sh
. "$repo/ci/lib.sh"

out=${CI_OUT:-$repo/ci-out}
mkdir -p "$out"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fail() {
    echo "ERRO: $*" >&2
    printf '## Testes de unidade\n\n**Falhou:** %s\n' "$*" > "$out/summary.md"
    exit 1
}

cfg="$work/cfg"
copy_repo "$cfg" || fail "não consegui copiar o repositório para a pasta temporária"
# Os imports e a lista suites do runner (unit_suites, do ci/lib.sh).
unit_suites "$cfg" || fail "$UNIT_ERROR"

# Só na cópia: o repositório nunca é instrumentado (o coverage.py recusa uma
# pasta com .git).
python3 "$repo/ci/coverage.py" instrument "$cfg" || fail "a instrumentação da cobertura falhou (veja acima)"

# Roda e confere RESULT e SUITE de cada teste (unit_run, do ci/lib.sh).
unit_run "$cfg" "$out/unit.log" || fail "$UNIT_ERROR"
result=$UNIT_RESULT

# O gate da cobertura: toda função do escopo de tests/coverage.json chamada.
set +e
python3 "$repo/ci/coverage.py" report "$cfg" "$out/unit.log" --gate --md "$out/coverage.md" > "$out/coverage.txt"
cov=$?
set -e
cat "$out/coverage.txt"
{
    printf '## Testes de unidade\n\n%s\n\n' "$result"
    [ "$cov" -eq 0 ] || printf '**Falhou:** o gate da cobertura (veja os erros abaixo e o coverage.txt).\n\n'
    cat "$out/coverage.md" 2> /dev/null || printf '**Cobertura:** o relatório não foi gerado (veja o log do job).\n'
} > "$out/summary.md"
if [ "$cov" -ne 0 ]; then
    echo "ERRO: o gate da cobertura reprovou: função do escopo sem teste ou tests/coverage.json desatualizado (veja os ERRO acima e o coverage.txt)" >&2
    exit 1
fi
echo "unidade: ok ($result, cobertura completa)"
