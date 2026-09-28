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
export XDG_RUNTIME_DIR="$work/run"
install -d -m 700 "$XDG_RUNTIME_DIR"

fail() {
    echo "ERRO: $*" >&2
    printf '## Testes de unidade\n\n**Falhou:** %s\n' "$*" > "$out/summary.md"
    exit 1
}

cfg="$work/cfg"
copy_repo "$cfg" || fail "não consegui copiar o repositório para a pasta temporária"
runner="$cfg/tests/runner.qml"
[ -f "$runner" ] || fail "falta o tests/runner.qml"

shopt -s nullglob
tests=("$cfg"/tests/*.test.js)
shopt -u nullglob
[ ${#tests[@]} -gt 0 ] || fail "nenhum tests/*.test.js: não há o que testar"

# Todo arquivo de teste precisa estar importado no runner e na lista suites,
# com o nome do arquivo e o módulo do import (um item copiado com o nome
# trocado rodaria outro arquivo no lugar deste).
names=()
for f in "${tests[@]}"; do
    name=$(basename "$f" .test.js)
    # O nome vai numa regex e numa string JS: só letras, números, _ e -.
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || fail "tests/$name.test.js: nome de arquivo de teste só com letras, números, _ e -"
    module=$(sed -nE "s/^import \"$name\\.test\\.js\" as ([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\$/\\1/p" "$runner" | head -n 1)
    [ -n "$module" ] || fail "tests/$name.test.js não está importado no tests/runner.qml (falta a linha: import \"$name.test.js\" as <Nome>Test)"
    grep -qE "^[[:space:]]*\[\"$name\", $module\],?[[:space:]]*\$" "$runner" \
        || fail "tests/$name.test.js está importado como $module, mas falta o item [\"$name\", $module] em suites no tests/runner.qml (fora de suites, ele nunca roda)"
    names+=("$name")
done

# Só na cópia: o repositório nunca é instrumentado (o coverage.py recusa uma
# pasta com .git).
python3 "$repo/ci/coverage.py" instrument "$cfg" || fail "a instrumentação da cobertura falhou (veja acima)"

cp "$runner" "${tests[@]}" "$cfg/"

set +e
env -u LUCERNA_DEV TZ=America/Sao_Paulo QT_QPA_PLATFORM=offscreen \
    timeout -k 10 60 qs -p "$cfg/runner.qml" > "$work/raw.log" 2>&1
rc=$?
set -e
sed 's/\x1b\[[0-9;]*m//g' "$work/raw.log" > "$out/unit.log"
grep -E 'PASS |FAIL |SUITE |RESULT ' "$out/unit.log" || true

# O qs prefixa cada linha de console.* com a categoria e "qml:" (ex.: "  INFO
# qml: PASS ..." e "  ERROR qml: FAIL ..."). As checagens de SUITE e RESULT
# ancoram nesse prefixo (início da linha) e no fim dela: sem âncora, uma
# mensagem de FAIL que citasse "SUITE x casos=3" ou "RESULT passed=0 failed=0"
# no texto passaria pela checagem sem ter rodado nada.
qs_line='^[[:space:]]*[A-Za-z]+ qml: '

result_line=$(grep -E "${qs_line}RESULT passed=[0-9]+ failed=[0-9]+\$" "$out/unit.log" | tail -n 1 || true)
result=$(sed -E "s/${qs_line}//" <<< "$result_line")
if [ -z "$result" ]; then
    echo "--- unit.log ---" >&2
    tail -n 40 "$out/unit.log" >&2
    fail "o runner não chegou ao fim (sem a linha RESULT; código $rc: 124 é o timeout, 255 um import ou JS que não carrega). Veja unit.log"
fi
passed=$(sed -E 's/.*passed=([0-9]+).*/\1/' <<< "$result")
failed=$(sed -E 's/.*failed=([0-9]+).*/\1/' <<< "$result")
if [ "$rc" -ne 0 ] || [ "$failed" -ne 0 ] || [ "$passed" -eq 0 ]; then
    fail "testes falharam ($result, código $rc)"
fi

# Todo arquivo de teste precisa ter rodado: importado e fora de suites, ou sem
# nenhum caso, ele passaria calado.
for name in "${names[@]}"; do
    grep -qE "${qs_line}SUITE $name casos=[1-9][0-9]*\$" "$out/unit.log" \
        || fail "tests/$name.test.js não rodou nenhum caso (falta \"SUITE $name casos=N\" com N > 0): confira o item [\"$name\", …] em suites no tests/runner.qml e os t.test do arquivo"
done

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
