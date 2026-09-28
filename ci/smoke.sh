#!/usr/bin/env bash
# Teste de fumaça: sobe o sway headless (o Hyprland não sobe sem GPU), roda o
# shell instrumentado numa cópia do repositório (copy_repo, do ci/lib.sh), abre
# cada painel por IPC, confere o `panels get`, tira uma captura de cada estado e
# reprova com aviso ou erro fora do ci/tolerated.txt. A unidade roda de novo
# numa cópia separada (unit_suites e unit_run, do ci/lib.sh), e a cobertura de
# todas as funções (unidade + fumaça) sai junto, sem bloquear.
#
# Reprova com: função fora do padrão na instrumentação --all (arquivo:linha),
# sway ou shell que não sobe (sem "Configuration Loaded" no log), `ipc call`
# com código diferente de 0, `panels get` diferente do esperado, painel que não
# fecha, shell que cai, aviso ou erro fora do ci/tolerated.txt e a unidade da
# cópia separada que falha.
#
# O que a fumaça não confere por IPC: a aba do painel superior, a seção do
# painel lateral e o tópico das configurações que ficaram abertos. Os IPCs
# dashboard, sidebar e settings só têm open/toggle, nenhum devolve o estado
# atual; uma aba, seção ou tópico que não abre só aparece como erro no log (o
# logcheck) e na captura.
#
# Saída em $CI_OUT: shell.log, sway.log, unit-smoke.log, shots/NN-<passo>.png,
# coverage.md e summary.md (tabela passo, esperado, veio).
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=ci/lib.sh
. "$repo/ci/lib.sh"

out=${CI_OUT:-$repo/ci-out}
mkdir -p "$out/shots"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
pids=()
logs_checked=0
# clean_log: o log do shell (a saída crua do qs) sem cores, em $CI_OUT.
clean_log() {
    if [ -f "$work/raw.log" ]; then
        sed 's/\x1b\[[0-9;]*m//g' "$work/raw.log" > "$out/shell.log"
    fi
}
# shellcheck disable=SC2329 # chamada pelo trap
cleanup() {
    local p
    pkill -TERM -u "$(id -u)" -f "qs -c lucerna" 2> /dev/null || true
    for p in "${pids[@]}"; do
        kill "$p" 2> /dev/null || true
    done
    for p in "${pids[@]}"; do
        wait "$p" 2> /dev/null || true
    done
    # O que o shell escreveu até o fim (inclusive depois de uma falha) vai para
    # o artefato.
    clean_log || true
    rm -rf "$work"
}
trap cleanup EXIT

summary="$out/summary.md"
{
    printf '## Fumaça\n\n'
    printf '| Passo | Esperado | Veio |\n| --- | --- | --- |\n'
} > "$summary"

# fail <mensagem>: reprova. Antes da conferência final do log, mostra também os
# avisos e erros do log até aqui que o ci/tolerated.txt não cobre (a causa de
# um painel que não abriu costuma estar lá).
fail() {
    echo "ERRO: $*" >&2
    printf '\n**Falhou:** %s\n' "$*" >> "$summary"
    if [ "$logs_checked" = 0 ] && [ -f "$work/raw.log" ]; then
        clean_log
        echo "--- avisos e erros do log até aqui, fora do ci/tolerated.txt ---" >&2
        python3 "$repo/ci/logcheck.py" "$repo/ci/tolerated.txt" "$out/shell.log" "$out/sway.log" >&2 || true
    fi
    exit 1
}

# row <passo> <esperado> <veio>: uma linha da tabela do summary.md.
row() {
    printf '| %s | %s | %s |\n' "$1" "$2" "$3" >> "$summary"
}

export XDG_RUNTIME_DIR="$work/run" XDG_CONFIG_HOME="$work/config" XDG_STATE_HOME="$work/state" XDG_CACHE_HOME="$work/cache"
install -d -m 700 "$XDG_RUNTIME_DIR"
cfg="$XDG_CONFIG_HOME/quickshell/lucerna"
copy_repo "$cfg" || fail "não consegui copiar o repositório para a pasta de configuração do shell"
# Com --all, toda função de todos os .qml precisa estar no padrão
# `function nome(...) {` numa linha: o coverage.py lista cada uma fora dele como
# "arquivo:linha: função fora do padrão" e sai com 1. Nada é pulado.
python3 "$repo/ci/coverage.py" instrument "$cfg" --all \
    || fail "a instrumentação (--all) achou função fora do padrão \"function nome(...) {\" numa linha (arquivo:linha acima): ponha a declaração inteira numa linha no .qml"

# sway headless com uma saída de 1920x1080. Sem o Xwayland e sem o swaybg (o
# fundo é do próprio shell): o container não tem nenhum dos dois, e o sway
# registraria um ERROR para cada um. O socket é o primeiro wayland-* que ele
# abrir (o nome muda com o que já existe no XDG_RUNTIME_DIR), detectado, não
# fixo.
printf '%s\n' 'output HEADLESS-1 resolution 1920x1080' 'xwayland disable' 'swaybg_command -' > "$work/sway.cfg"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
    sway -c "$work/sway.cfg" > "$out/sway.log" 2>&1 &
sway_pid=$!
pids+=("$sway_pid")
socket=""
for _ in $(seq 100); do
    socket=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' | sort | head -n 1)
    [ -n "$socket" ] && break
    kill -0 "$sway_pid" 2> /dev/null || break
    sleep 0.2
done
[ -n "$socket" ] || fail "o sway não abriu nenhum socket wayland-* em $XDG_RUNTIME_DIR em 20 s (veja sway.log)"
row "sway headless" "um socket wayland-*" "$socket"
export WAYLAND_DISPLAY=$socket QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software

dbus-run-session -- qs -c lucerna > "$work/raw.log" 2>&1 &
qs_pid=$!
pids+=("$qs_pid")
for _ in $(seq 120); do
    grep -q "Configuration Loaded" "$work/raw.log" && break
    kill -0 "$qs_pid" 2> /dev/null || break
    sleep 0.5
done
clean_log
if ! grep -q "Configuration Loaded" "$out/shell.log"; then
    row "shell carregado" "Configuration Loaded" "(não veio)"
    fail "o shell não carregou (sem \"Configuration Loaded\" no log: o qs saiu antes ou passaram 60 s; veja shell.log)"
fi
row "shell carregado" "Configuration Loaded" "Configuration Loaded"

ipc() { qs -c lucerna ipc call "$@"; }
n=0
grim "$out/shots/00-inicio.png" || fail "o grim não capturou a tela inicial"

# step <esperado no panels get> <alvo> <função> [argumentos...]: chama o IPC,
# confere que o shell continua vivo e que o `panels get` traz o painel
# esperado, tira a captura e fecha tudo (panels close), conferindo que o
# `panels get` volta vazio.
step() {
    local expected=$1 name got
    shift
    n=$((n + 1))
    name=$(printf '%02d-%s' "$n" "$(printf '%s-' "$@" | tr -cd 'a-z0-9-' | sed 's/-*$//')")
    ipc "$@" > /dev/null || fail "ipc call $* saiu com código $?"
    sleep 1
    kill -0 "$qs_pid" 2> /dev/null || fail "o shell caiu depois de: ipc call $*"
    got=$(ipc panels get) || fail "ipc call panels get saiu com código $?"
    row "ipc call $*" "$expected" "${got:-(nenhum)}"
    [ "$got" = "$expected" ] || fail "depois de \"ipc call $*\", o panels get trouxe \"$got\"; o esperado era \"$expected\""
    grim "$out/shots/$name.png" || fail "o grim não capturou $name"
    ipc panels close > /dev/null || fail "ipc call panels close saiu com código $?"
    got=$(ipc panels get) || fail "ipc call panels get saiu com código $?"
    [ -z "$got" ] || fail "depois de \"ipc call panels close\" (passo $name), o panels get trouxe \"$got\"; o esperado era nenhum painel"
}

step launcher panels open launcher
step launcher launcher open files ""
for tab in overview media performance weather; do
    step dashboard dashboard open "$tab"
done
for section in wifi bluetooth sound notifications battery display; do
    step sidebar sidebar open "$section"
done
for topic in appearance wallpaper displays idle nightlight launcher clipboard capture mouse keyboard glass \
    notifications panels sidebar bar dashboard power shortcuts about; do
    step settings settings open "$topic"
done
step themes panels open themes
step power panels open power
step clipboard clipboard open
step capture capture open shot
step overview overview toggle

ipc cov dump > "$work/hits-smoke.txt" || fail "não consegui ler a cobertura (ipc call cov dump saiu com código $?)"
kill -0 "$qs_pid" 2> /dev/null || fail "o shell caiu no fim da fumaça"
row "shell vivo no fim" "sim" "sim"
clean_log

# A unidade numa cópia separada (nunca na pasta de config do shell que está
# rodando), instrumentada igual (--all), para a cobertura informativa juntar as
# duas. As chaves são caminhos relativos, iguais nas duas cópias. A conferência
# (código, RESULT e SUITE de cada teste) é a mesma do ci/unit.sh.
unit="$work/unit"
copy_repo "$unit" || fail "não consegui copiar o repositório para a cópia da unidade"
python3 "$repo/ci/coverage.py" instrument "$unit" --all > /dev/null || fail "a instrumentação da cópia da unidade falhou (veja acima)"
unit_suites "$unit" || fail "unidade na cópia da fumaça: $UNIT_ERROR"
unit_run "$unit" "$out/unit-smoke.log" > /dev/null || fail "unidade na cópia da fumaça: $UNIT_ERROR"
row "unidade na cópia separada" "failed=0" "$UNIT_RESULT"

# O relatório é informativo (sem --gate): nem ele nem um coverage.md que falte
# derrubam a fumaça.
python3 "$repo/ci/coverage.py" report "$cfg" "$out/unit-smoke.log" "$work/hits-smoke.txt" --md "$out/coverage.md" \
    > "$out/coverage.txt" || echo "aviso: o relatório informativo da cobertura falhou (veja coverage.txt)" >&2
head -n 1 "$out/coverage.txt" 2> /dev/null || true
{
    printf '\n'
    cat "$out/coverage.md" 2> /dev/null || printf '**Cobertura:** o relatório não foi gerado (informativo).\n'
} >> "$summary"

logs_checked=1
python3 "$repo/ci/logcheck.py" "$repo/ci/tolerated.txt" "$out/shell.log" "$out/sway.log" \
    || fail "há avisos ou erros fora do ci/tolerated.txt (listados acima)"
echo "fumaça: ok ($n passos)"
