#!/usr/bin/env bash
# Compila os wallpapers animados: themes/shaders/*.frag → *.qsb.
# Cada .frag recebe antes o trecho comum (uniforms e funções de ruído).
# Requer o qsb (pacote qt6-shadertools).
#   dev/shaders.sh          grava ao lado dos .frag
#   dev/shaders.sh PASTA    grava em PASTA (o ci/rules.py compara com os do repositório)
set -euo pipefail
src="$(cd "$(dirname "$0")/../themes/shaders" && pwd)"
dest="${1:-$src}"
mkdir -p "$dest"
dest="$(cd "$dest" && pwd)"
cd "$src"
QSB=$(command -v qsb || echo /usr/lib/qt6/bin/qsb)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for frag in *.frag; do
    name=${frag%.frag}
    { echo "#version 440"; cat common.glsl; cat "$frag"; } > "$tmp/$name.frag"
    # Só GLSL de desktop e SPIR-V (Vulkan): a variante GLSL ES sai com mediump,
    # e GPUs que calculam mediump em 16 bits desenham os degradês em faixas.
    "$QSB" --glsl "150,330" -O -o "$dest/$name.qsb" "$tmp/$name.frag"
    echo "$name.qsb"
done
