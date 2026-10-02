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
# fecha, shell que cai (inclusive no repouso de 5 s depois do último passo),
# shell que não encerra limpo com `qs kill` (código 0 em 10 s), aviso ou erro
# fora do ci/tolerated.txt no log final (conferido depois do encerramento), a
# unidade da cópia separada que falha e todo `ipc call` ou grim que passa de
# 10 s (timeout, com o fim do shell.log na saída) ou o dbus-run-session que não
# sai em 10 s depois do shell.
#
# Só encerra os próprios processos (o grupo do sway e o do shell, por PID),
# nunca por nome: rodada fora do container, não derruba a sessão do usuário.
#
# O que a fumaça não confere por IPC: a aba do painel superior, a página da
# central e o tópico das configurações que ficaram abertos. Os IPCs dashboard,
# central e settings não devolvem o estado atual; uma aba, página ou tópico
# que não abre só aparece como erro no log (o logcheck) e na captura.
#
# Saída em $CI_OUT: shell.log, sway.log, kill.log, unit-smoke.log, shots/NN-<passo>.png,
# coverage.md e summary.md (tabela passo, esperado, veio).
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=ci/lib.sh
. "$repo/ci/lib.sh"

out=${CI_OUT:-$repo/ci-out}
mkdir -p "$out/shots"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
# O sway e o shell rodam cada um no próprio grupo de processos (setsid), e só
# esses grupos são encerrados: nada é morto por nome, para a fumaça rodada fora
# do container nunca derrubar o shell ou o sway de verdade do usuário.
sway_pid=""
qs_pid=""
shell_pid=""
logs_checked=0
# clean_log: o log do shell (a saída crua do qs) sem cores, em $CI_OUT.
clean_log() {
    if [ -f "$work/raw.log" ]; then
        sed 's/\x1b\[[0-9;]*m//g' "$work/raw.log" > "$out/shell.log"
    fi
}
# stop_group <pid>: encerra o grupo de processos que <pid> lidera (TERM; KILL
# se sobrar alguém depois de 5 s) e o recolhe.
stop_group() {
    local pid=$1
    [ -n "$pid" ] || return 0
    kill -TERM -- "-$pid" 2> /dev/null || true
    for _ in $(seq 20); do
        kill -0 -- "-$pid" 2> /dev/null || break
        sleep 0.25
    done
    kill -KILL -- "-$pid" 2> /dev/null || true
    wait "$pid" 2> /dev/null || true
}
# shellcheck disable=SC2329 # chamada pelo trap
cleanup() {
    stop_group "$qs_pid"
    stop_group "$sway_pid"
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
        # O fim do log é o trecho de um travamento (o que o shell fazia quando parou).
        echo "--- últimas linhas do shell.log ---" >&2
        tail -n 15 "$out/shell.log" >&2 2> /dev/null || true
    fi
    exit 1
}

# why <código>: o texto do código de saída de um comando com `timeout`; o 124 é
# o timeout (o shell travou ou o comando não respondeu).
why() {
    if [ "$1" -eq 124 ]; then
        echo "timeout de $CMD_TIMEOUT s (o shell travou ou não respondeu; o shell.log tem o trecho)"
    else
        echo "código $1"
    fi
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
# Num script, o filho em segundo plano não lidera grupo: o setsid cria a sessão
# sem outro fork, e o PID do sway é o do grupo.
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
    setsid sway -c "$work/sway.cfg" > "$out/sway.log" 2>&1 &
sway_pid=$!
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

# O shell grava o próprio PID (o bash do meio dá lugar ao qs com exec): é por
# ele que a fumaça confere que o shell continua vivo e o encerra no fim.
# shellcheck disable=SC2016 # o $$ e o $1 expandem no bash de dentro
setsid dbus-run-session -- bash -c 'echo "$$" > "$1" && exec qs -c lucerna' _ "$work/qs.pid" > "$work/raw.log" 2>&1 &
qs_pid=$!
for _ in $(seq 120); do
    [ -z "$shell_pid" ] && [ -s "$work/qs.pid" ] && shell_pid=$(cat "$work/qs.pid")
    grep -q "Configuration Loaded" "$work/raw.log" && break
    kill -0 "$qs_pid" 2> /dev/null || break
    sleep 0.5
done
[ -n "$shell_pid" ] || shell_pid=$(cat "$work/qs.pid" 2> /dev/null || true)
clean_log
if ! grep -q "Configuration Loaded" "$out/shell.log"; then
    row "shell carregado" "Configuration Loaded" "(não veio)"
    fail "o shell não carregou (sem \"Configuration Loaded\" no log: o qs saiu antes ou passaram 60 s; veja shell.log)"
fi
row "shell carregado" "Configuration Loaded" "Configuration Loaded"

[ -n "$shell_pid" ] || fail "não achei o PID do shell ($work/qs.pid vazio)"

# alive: o shell (o próprio qs, não o dbus-run-session em volta) está rodando.
alive() { kill -0 "$shell_pid" 2> /dev/null; }
# Todo `ipc call` e todo grim têm timeout: sem ele, um shell travado deixaria o
# job parado até o limite do workflow, sem diagnóstico.
CMD_TIMEOUT=10
ipc() { timeout "$CMD_TIMEOUT" qs -c lucerna ipc call "$@"; }
shot() { timeout "$CMD_TIMEOUT" grim "$1"; }
n=0
shot "$out/shots/00-inicio.png" || fail "o grim não capturou a tela inicial: $(why $?)"

# step <esperado no panels get> <alvo> <função> [argumentos...]: chama o IPC,
# confere que o shell continua vivo e que o `panels get` traz o painel
# esperado, tira a captura e fecha tudo (panels close), conferindo que o
# `panels get` volta vazio.
step() {
    local expected=$1 name got
    shift
    n=$((n + 1))
    name=$(printf '%02d-%s' "$n" "$(printf '%s-' "$@" | tr -cd 'a-z0-9-' | sed 's/-*$//')")
    ipc "$@" > /dev/null || fail "ipc call $* falhou: $(why $?)"
    sleep 1
    alive || fail "o shell caiu depois de: ipc call $*"
    got=$(ipc panels get) || fail "ipc call panels get falhou: $(why $?)"
    row "ipc call $*" "$expected" "${got:-(nenhum)}"
    [ "$got" = "$expected" ] || fail "depois de \"ipc call $*\", o panels get trouxe \"$got\"; o esperado era \"$expected\""
    shot "$out/shots/$name.png" || fail "o grim não capturou $name: $(why $?)"
    ipc panels close > /dev/null || fail "ipc call panels close falhou: $(why $?)"
    got=$(ipc panels get) || fail "ipc call panels get falhou: $(why $?)"
    [ -z "$got" ] || fail "depois de \"ipc call panels close\" (passo $name), o panels get trouxe \"$got\"; o esperado era nenhum painel"
}

step launcher panels open launcher
# Nome que já foi painel (a barra lateral saiu): o IPC ignora e nada abre.
step "" panels open sidebar
step launcher launcher open files ""
for tab in overview media performance weather; do
    step dashboard dashboard open "$tab"
done
for entry in "" rede bluetooth som notificacoes energia; do
    step central central open "$entry"
done
step central central toggle som
for topic in appearance wallpaper displays idle nightlight launcher clipboard capture mouse keyboard glass \
    notifications panels bar dashboard power shortcuts about; do
    step settings settings open "$topic"
done
step themes panels open themes
step power panels open power
step clipboard clipboard open
step capture capture open shot
step overview overview toggle

# Repouso: o shell fica parado alguns segundos depois do último passo, para o
# que chega tarde (um Timer, uma resposta assíncrona, o efeito do último
# panels close) cair no log antes do veredito.
sleep 5
alive || fail "o shell caiu no repouso depois do último passo"
ipc cov dump > "$work/hits-smoke.txt" || fail "não consegui ler a cobertura (ipc call cov dump falhou: $(why $?))"
alive || fail "o shell caiu no fim da fumaça"
row "shell vivo depois de 5 s de repouso" "sim" "sim"

# Encerra o shell antes do veredito, pelo PID dele (qs kill --pid, a saída
# limpa do Quickshell), e espera o fim: o log conferido é o final, com o
# encerramento, e é o mesmo que vai para o artefato.
qs kill --pid "$shell_pid" > "$out/kill.log" 2>&1 || true
for _ in $(seq 40); do
    alive || break
    sleep 0.25
done
if alive; then
    row "shell encerrado (qs kill)" "em 10 s, código 0" "(não encerrou)"
    fail "o shell não encerrou em 10 s depois do qs kill --pid $shell_pid"
fi
# O dbus-run-session sai logo depois do shell; o laço limitado (10 s) evita que
# o wait prenda o job se ele não sair. Um zumbi (filho já terminado, ainda não
# recolhido) conta como terminado.
running() { [ -r "/proc/$1/stat" ] && [ "$(sed 's/.*) //' "/proc/$1/stat" | cut -c1)" != Z ]; }
for _ in $(seq 40); do
    running "$qs_pid" || break
    sleep 0.25
done
if running "$qs_pid"; then
    row "dbus-run-session encerrado" "em 10 s" "(não saiu)"
    fail "o dbus-run-session não terminou em 10 s depois do shell encerrar (veja shell.log)"
fi
code=0
wait "$qs_pid" || code=$?
qs_pid=""
clean_log
row "shell encerrado (qs kill)" "em 10 s, código 0" "código $code"
[ "$code" -eq 0 ] || fail "o shell encerrou com código $code depois do qs kill (veja shell.log)"

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
