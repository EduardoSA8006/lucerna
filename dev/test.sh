#!/usr/bin/env bash
# Harness da conferência visual: sobe o Lucerna num container próprio
# (lucerna-polish, da imagem lucerna-dev do dev/run.sh), com o Hyprland aninhado
# numa janela na tela do usuário, e dá os comandos para reiniciar o shell, ler o
# log, chamar IPC, mudar a config e capturar a tela. Nunca toca o container
# lucerna-dev (o do dev/run.sh, que é do usuário).
#   dev/test.sh up                (re)cria o container e espera o shell carregar
#   dev/test.sh down               remove o container
#   dev/test.sh restart            reinicia o qs e espera carregar
#   dev/test.sh log [N]            as N últimas linhas do log (padrão 40), sem ruído
#   dev/test.sh errs               só os avisos e erros do log
#   dev/test.sh ipc ARGS...        qs -c lucerna ipc call ARGS...
#   dev/test.sh setc 'dict(...)'   mescla o dicionário (Python) no config.json do shell
#   dev/test.sh shot NOME          captura a tela em $LUCERNA_TEST_OUT/NOME.png
#   dev/test.sh see PREFIXO ARGS...  ipc call ARGS, 1 s, captura PREFIXO-ARGS.png, fecha
#   dev/test.sh run 'COMANDO'      roda um comando na sessão (notify-send, hyprctl...)
# LUCERNA_TEST_OUT: pasta das capturas (padrão /tmp/lucerna-test).
# LUCERNA_TEST_GPU="/dev/dri/renderDN /dev/dri/cardN": força a GPU repassada.
# Um `hyprctl reload` ou fechar a janela derruba a saída do Hyprland aninhado
# (ele cai no monitor FALLBACK e as capturas saem vazias): dev/test.sh up de novo.
#
# Roteiro de referência ("antes-*", a linha de base capturada antes das
# correções das Tarefas 21 a 28; regenerar a partir do repositório, com o
# container de pé):
#   p=antes
#   dev/test.sh see $p panels open launcher
#   dev/test.sh see $p launcher open files ""
#   for tab in overview media performance weather; do dev/test.sh see $p dashboard open "$tab"; done
#   for s in wifi bluetooth sound notifications battery display; do dev/test.sh see $p sidebar open "$s"; done
#   for t in appearance wallpaper displays idle nightlight launcher clipboard capture mouse keyboard glass \
#       notifications panels sidebar bar dashboard power shortcuts about; do dev/test.sh see $p settings open "$t"; done
#   dev/test.sh see $p panels open themes
#   dev/test.sh see $p panels open power
#   dev/test.sh see $p clipboard open
#   dev/test.sh see $p capture open shot
#   dev/test.sh ipc session lock; sleep 1; dev/test.sh shot $p-bloqueio; dev/test.sh run 'wtype lucerna && wtype -k Return'
#   dev/test.sh run 'notify-send "Teste do Lucerna" "Corpo da notificação, comprido o bastante para quebrar em duas linhas"'; sleep 1; dev/test.sh shot $p-popup
#   dev/test.sh ipc brightness up; dev/test.sh shot $p-osd; dev/test.sh ipc brightness down
#   for e in strip island pill islands; do dev/test.sh setc "dict(barStyle='$e')"; sleep 1; dev/test.sh shot $p-barra-$e; done; dev/test.sh setc "dict(barStyle='strip')"
#   for e in compact full grid; do dev/test.sh setc "dict(launcherStyle='$e')"; dev/test.sh see $p-$e launcher open apps ""; done; dev/test.sh setc "dict(launcherStyle='compact')"
#   # Nesta imagem, o Hyprland (0.56.2, config Lua) não aceita mais o
#   # `hyprctl dispatch exec "[workspace N silent] CMD"` clássico (dá erro de
#   # parser Lua); use a forma hl.dsp abaixo.
#   dev/test.sh run "hyprctl dispatch 'hl.dsp.exec_cmd(\"[workspace 2 silent] kitty\")'"
#   dev/test.sh run "hyprctl dispatch 'hl.dsp.exec_cmd(\"[workspace 3 silent] foot\")'"; sleep 2; dev/test.sh see $p overview toggle
#
#   Extras para as Tarefas 22, 24, 26 e 27 (telas que essas conferências
#   comparam e que o roteiro acima não cobre):
#   dev/test.sh run 'notify-send "Teste do Lucerna" "Corpo da notificação, comprido o bastante para quebrar em duas linhas"'
#   dev/test.sh see $p-caixa sidebar open notifications
#   dev/test.sh setc 'dict(transparencyOverride=dict(enabled=True))'; dev/test.sh see $p-vidro settings open glass; dev/test.sh setc 'dict(transparencyOverride=dict())'
#   dev/test.sh setc "dict(launcherStyle='full')"; dev/test.sh see $p-full-busca launcher open apps kitty; dev/test.sh setc "dict(launcherStyle='compact')"
#   dev/test.sh run 'printf "texto de teste" | wl-copy'; dev/test.sh see $p-clipboard clipboard open
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name=lucerna-polish
image=lucerna-dev
out=${LUCERNA_TEST_OUT:-/tmp/lucerna-test}
# "dropped operation" fica de fora: é o sintoma do bug do Config (spec linha
# 112); se voltar, tem que aparecer no log e no errs, não ser filtrado.
noise='portal'

fail() {
    echo "ERRO: $*" >&2
    exit 1
}

# A GPU repassada: o primeiro nó de render que não é da NVIDIA (o container não
# tem os drivers dela) e o card do mesmo dispositivo PCI.
gpu() {
    local node dev card
    if [ -n "${LUCERNA_TEST_GPU:-}" ]; then
        echo "$LUCERNA_TEST_GPU"
        return 0
    fi
    for node in /sys/class/drm/renderD*; do
        [ -e "$node/device/vendor" ] || continue
        [ "$(cat "$node/device/vendor")" = 0x10de ] && continue
        dev=$(readlink -f "$node/device")
        for card in /sys/class/drm/card[0-9]*; do
            case "${card##*/}" in *-*) continue ;; esac
            if [ "$(readlink -f "$card/device")" = "$dev" ]; then
                echo "/dev/dri/${node##*/} /dev/dri/${card##*/}"
                return 0
            fi
        done
    done
    return 1
}

# ex 'COMANDO': roda no container com o ambiente da sessão do Hyprland (D-Bus,
# instância e o socket Wayland do Hyprland aninhado, achado pelo nome).
ex() {
    docker exec -i "$name" bash -c '
        pid=$(pgrep -x Hyprland) || { echo "ERRO: o Hyprland não está rodando no container" >&2; exit 3; }
        export "$(tr "\0" "\n" < "/proc/$pid/environ" | grep ^DBUS_SESSION_BUS_ADDRESS=)"
        HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$XDG_RUNTIME_DIR/hypr" | head -n 1)
        WAYLAND_DISPLAY=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name "wayland-[0-9]*" -printf "%f\n" | sort | head -n 1)
        export HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY
        '"$1"
}

running() {
    [ "$(docker inspect -f '{{.State.Running}}' "$name" 2> /dev/null)" = true ] \
        || fail "o container $name não está de pé: rode dev/test.sh up"
}

# Espera o "Configuration Loaded" da instância atual do shell (até 60 s).
wait_loaded() {
    for _ in $(seq 120); do
        if ex 'qs -c lucerna log 2> /dev/null' 2> /dev/null | grep -q "Configuration Loaded"; then
            return 0
        fi
        sleep 0.5
    done
    ex 'qs -c lucerna log 2>&1 | tail -n 30' || true
    fail "o shell não carregou em 60 s (log acima)"
}

setc() {
    running
    docker exec -i -e SETC="$1" "$name" python3 -c '
import glob, json, os, sys, time

pattern = os.path.expanduser("~/.local/state/quickshell/by-shell/*/config.json")
for _ in range(40):
    paths = glob.glob(pattern)
    if paths:
        break
    time.sleep(0.25)
if len(paths) != 1:
    sys.exit(f"ERRO: esperava um config.json em {pattern}, achei {len(paths)}")
with open(paths[0], encoding="utf-8") as f:
    data = json.load(f)
# Expressão do próprio usuário na linha de comando; só dict e as constantes.
names = {"__builtins__": {}, "dict": dict, "True": True, "False": False, "None": None}
data.update(eval(os.environ["SETC"], names))
with open(paths[0], "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
print("config:", os.environ["SETC"])
'
}

# shot NOME: captura a saída do Hyprland aninhado em $out/NOME.png. Com
# timeout: se a janela do host estiver escondida ou minimizada, o Hyprland
# aninhado para de desenhar e o grim trava esperando um frame que não vem.
shot() {
    running
    ex 'hyprctl monitors | grep -q "^Monitor WAYLAND-1 "' \
        || fail "a saída WAYLAND-1 sumiu (Hyprland no FALLBACK, depois de um reload ou da janela fechada): rode dev/test.sh up"
    mkdir -p "$out"
    ex 'timeout 10 grim -o WAYLAND-1 /tmp/lucerna-shot.png' \
        || fail "a captura travou: a janela de teste está escondida ou minimizada? Traga-a para a frente (não precisa de foco) e tente de novo."
    docker cp -q "$name:/tmp/lucerna-shot.png" "$out/$1.png"
    echo "$out/$1.png"
}

up() {
    : "${WAYLAND_DISPLAY:?precisa de uma sessão Wayland no host}"
    local runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)} devices render card
    devices=$(gpu) || fail "nenhuma GPU utilizável em /sys/class/drm (a da NVIDIA não funciona no container); use LUCERNA_TEST_GPU"
    read -r render card <<< "$devices"
    if ! docker image inspect "$image" &> /dev/null; then
        docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t "$image" "$repo/dev"
    fi
    local extra=()
    if [ -S "$runtime/pipewire-0" ]; then
        extra+=(-v "$runtime/pipewire-0:/run/user/1000/pipewire-0")
    fi
    if [ -S /run/dbus/system_bus_socket ]; then
        extra+=(-v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket)
    fi
    docker rm -f "$name" &> /dev/null || true
    docker run -d --name "$name" \
        --user "$(id -u):$(id -g)" \
        --device "$render" --device "$card" \
        -e WAYLAND_DISPLAY=wayland-host \
        -e LUCERNA_DEV=1 \
        -v /etc/localtime:/etc/localtime:ro \
        -v "$runtime/$WAYLAND_DISPLAY:/run/user/1000/wayland-host" \
        -v "$repo:/home/dev/.config/quickshell/lucerna" \
        -v "$repo/dev/hyprland.lua:/home/dev/.config/hypr/hyprland.lua:ro" \
        "${extra[@]}" \
        "$image" > /dev/null
    wait_loaded
    # Sem isso a ociosidade apaga a tela em 5 min e as capturas saem pretas.
    setc 'dict(idleEnabled=False)'
    echo "de pé: $name (GPU $render), capturas em $out"
}

case "${1:-}" in
    up) up ;;
    down) docker rm -f "$name" > /dev/null && echo "removido: $name" ;;
    restart)
        running
        ex 'pkill -x qs; sleep 0.5; setsid -f qs -c lucerna > /dev/null 2>&1 < /dev/null'
        wait_loaded
        echo "shell reiniciado"
        ;;
    log)
        running
        ex 'qs -c lucerna log 2>&1' | sed 's/\x1b\[[0-9;]*m//g' | grep -vE "$noise" | tail -n "${2:-40}"
        ;;
    errs)
        running
        found=$(ex 'qs -c lucerna log 2>&1' | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'WARN|ERROR|caused' | grep -vE "$noise" || true)
        if [ -n "$found" ]; then
            echo "$found"
        else
            echo "sem avisos nem erros"
        fi
        ;;
    ipc)
        running
        shift
        [ $# -gt 0 ] || fail "uso: dev/test.sh ipc ALVO FUNÇÃO [ARGUMENTOS...]"
        ex "qs -c lucerna ipc call $(printf '%q ' "$@")"
        ;;
    setc)
        [ -n "${2:-}" ] || fail "uso: dev/test.sh setc 'dict(chave=valor, ...)'"
        setc "$2"
        ;;
    shot)
        [ -n "${2:-}" ] || fail "uso: dev/test.sh shot NOME"
        shot "$2"
        ;;
    see)
        running
        [ $# -ge 3 ] || fail "uso: dev/test.sh see PREFIXO ALVO FUNÇÃO [ARGUMENTOS...]"
        # O prefixo passa pela mesma sanitização do resto do nome, para não
        # gravar fora de $out (ex.: um prefixo com "/" ou "..").
        prefix=$(printf '%s' "$2" | tr -cd 'a-z0-9-')
        shift 2
        ex "qs -c lucerna ipc call $(printf '%q ' "$@")" > /dev/null
        sleep 1
        shot "$prefix-$(printf '%s-' "$@" | tr -cd 'a-z0-9-' | sed 's/-*$//')"
        ex 'qs -c lucerna ipc call panels close' > /dev/null
        ;;
    run)
        running
        [ -n "${2:-}" ] || fail "uso: dev/test.sh run 'COMANDO'"
        ex "$2"
        ;;
    *)
        sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 2
        ;;
esac
