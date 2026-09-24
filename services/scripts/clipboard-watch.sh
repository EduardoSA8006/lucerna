#!/bin/sh
# Chamado pelo `wl-paste --watch` a cada mudança da área de transferência.
# Escreve uma linha por mudança:
#   text<TAB>BASE64          o texto (até 256 KiB), em base64 para caber numa linha
#   image<TAB>ARQUIVO<TAB>MD5 a imagem PNG, gravada na pasta dada
#   skip                     senha (gerenciadores marcam) ou algo sem texto nem imagem
#
# Uso: wl-paste --watch clipboard-watch.sh PASTA_DAS_IMAGENS
dir=$1
types=$(wl-paste --list-types 2>/dev/null)

case "$types" in
    *x-kde-passwordManagerHint*) echo skip; exit 0 ;;
esac

if printf '%s\n' "$types" | grep -qx 'image/png'; then
    mkdir -p "$dir"
    file="$dir/$(date +%s%N).png"
    wl-paste --type image/png > "$file" 2>/dev/null
    if [ -s "$file" ]; then
        printf 'image\t%s\t%s\n' "$file" "$(md5sum "$file" | cut -d' ' -f1)"
    else
        rm -f "$file"
        echo skip
    fi
elif printf '%s\n' "$types" | grep -qE '^(text/plain|UTF8_STRING|TEXT|STRING)'; then
    size=$(wl-paste --no-newline --type text 2>/dev/null | head -c 262145 | wc -c)
    if [ "$size" -gt 0 ] && [ "$size" -le 262144 ]; then
        printf 'text\t'
        wl-paste --no-newline --type text 2>/dev/null | base64 -w0
        echo
    else
        echo skip
    fi
else
    echo skip
fi
