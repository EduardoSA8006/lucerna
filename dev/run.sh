#!/usr/bin/env bash
# Sobe o Hyprland aninhado com o Lucerna montado em ~/.config/quickshell/lucerna.
#   dev/run.sh           constrói a imagem (se preciso) e abre a janela
#   dev/run.sh --build   força reconstruir a imagem
#   dev/run.sh shell     abre um bash no container em execução
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image=lucerna-dev
name=lucerna-dev

if [[ "${1:-}" == shell ]]; then
    exec docker exec -it "$name" bash
fi

: "${WAYLAND_DISPLAY:?precisa de uma sessão Wayland no host}"
socket="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$WAYLAND_DISPLAY"

if [[ "${1:-}" == --build ]] || ! docker image inspect "$image" &>/dev/null; then
    docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t "$image" "$repo/dev"
fi

# Só a GPU Intel é repassada: o container não tem os drivers da NVIDIA.
intel_render="$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-render)"
intel_card="$(readlink -f /dev/dri/by-path/pci-0000:00:02.0-card)"

exec docker run --rm -it \
    --name "$name" \
    --user "$(id -u):$(id -g)" \
    --device "$intel_render" --device "$intel_card" \
    -e WAYLAND_DISPLAY=wayland-host \
    -v "$socket:/run/user/1000/wayland-host" \
    -v "$repo:/home/dev/.config/quickshell/lucerna" \
    -v "$repo/dev/hyprland.lua:/home/dev/.config/hypr/hyprland.lua:ro" \
    "$image"
