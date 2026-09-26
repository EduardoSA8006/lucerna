#!/usr/bin/env bash
# Análise estática: qmllint (com a árvore de módulos do Quickshell), shellcheck,
# ruff e os JSON de tema. Roda todas as partes e falha se alguma falhar.
# Saída em $CI_OUT: um <parte>.log por parte e o summary.md.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out=${CI_OUT:-$repo/ci-out}
mkdir -p "$out"
status=0
summary="$out/summary.md"
printf '## Análise estática\n\n' > "$summary"

# part <nome> <comando...>: roda, guarda o log e anota o resultado.
part() {
    local name=$1
    shift
    echo "== $name"
    if "$@" > "$out/$name.log" 2>&1; then
        tail -n 3 "$out/$name.log"
        printf -- '- %s: ok\n' "$name" >> "$summary"
    else
        cat "$out/$name.log"
        echo "FALHOU: $name"
        printf -- '- %s: **falhou** (veja %s.log)\n' "$name" "$name" >> "$summary"
        status=1
    fi
}

cd "$repo" || exit 1
mapfile -t scripts < <(find ci dev services/scripts -name '*.sh' | sort)
mapfile -t pyfiles < <(find ci dev -name '*.py' | sort)

part shellcheck shellcheck "${scripts[@]}"
part ruff-check ruff check --no-cache "${pyfiles[@]}"
part ruff-format ruff format --no-cache --check "${pyfiles[@]}"
part json python3 ci/jsoncheck.py

exit "$status"
