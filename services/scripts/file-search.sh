#!/bin/sh
# Busca de arquivos para o launcher, na pasta pessoal (sem pastas ocultas).
# Com o fd, que é rápido e respeita o .gitignore; sem ele, o find. Sem busca,
# os arquivos usados recentemente (recently-used.xbel, que os apps GTK e Qt
# mantêm).
#
# A busca fica em até 6 níveis, no mesmo disco da pasta pessoal (não entra em
# discos montados dentro dela), sem node_modules e afins, e para em 4 s: numa
# pasta pessoal com máquinas virtuais e discos de dados, ir até o fundo levava
# mais de um minuto; assim, dezenas de milissegundos.
#
# Uso: file-search.sh TIPO BUSCA LIMITE
#   TIPO: all, documents, images, music, videos
# Saída: uma linha por arquivo: caminho<TAB>tamanho<TAB>modificação (epoch).
kind=$1 query=$2 limit=${3:-60}

case "$kind" in
    documents) exts="pdf doc docx odt ods odp xls xlsx ppt pptx txt md rtf csv epub tex" ;;
    images) exts="png jpg jpeg webp gif svg bmp tiff heic avif" ;;
    music) exts="mp3 flac ogg opus m4a wav aac wma" ;;
    videos) exts="mp4 mkv webm mov avi m4v wmv" ;;
    *) exts="" ;;
esac

matches_kind() {
    [ -z "$exts" ] && return 0
    ext=$(printf '%s' "${1##*.}" | tr 'A-Z' 'a-z')
    for e in $exts; do
        [ "$e" = "$ext" ] && return 0
    done
    return 1
}

emit() {
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        matches_kind "$f" || continue
        printf '%s\t%s\n' "$f" "$(stat -c '%s	%Y' "$f" 2>/dev/null)"
    done
}

if [ -z "$query" ]; then
    xbel="${XDG_DATA_HOME:-$HOME/.local/share}/recently-used.xbel"
    [ -f "$xbel" ] || exit 0
    # Os mais recentes primeiro. Os atributos vêm em qualquer ordem e o caminho,
    # codificado como URL.
    python3 - "$xbel" <<'PY' 2>/dev/null | emit | head -n "$limit"
import sys, urllib.parse, xml.etree.ElementTree as ET
items = []
for b in ET.parse(sys.argv[1]).getroot().iter("bookmark"):
    href = b.get("href", "")
    if href.startswith("file://"):
        items.append((b.get("modified", ""), urllib.parse.unquote(href[7:])))
for _, path in sorted(items, reverse=True):
    print(path)
PY
    exit 0
fi

if command -v fd >/dev/null; then
    set -- timeout 4 fd --type f --ignore-case --max-results $((limit * 4)) --fixed-strings \
        --max-depth 6 --one-file-system --exclude node_modules --exclude __pycache__ --exclude target
    for e in $exts; do
        set -- "$@" --extension "$e"
    done
    "$@" -- "$query" "$HOME" 2>/dev/null | emit | head -n "$limit"
else
    timeout 4 find "$HOME" -xdev -maxdepth 6 \( -name '.*' -o -name node_modules \) -prune -o -type f -iname "*$query*" -print 2>/dev/null | emit | head -n "$limit"
fi
