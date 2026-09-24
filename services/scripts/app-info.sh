#!/bin/sh
# Informações de um app que o .desktop não traz: versão, desenvolvedor, resumo
# e site. Vêm do pacote (pacman ou flatpak) e dos metadados AppStream
# (/usr/share/metainfo), quando o app os tem.
#
# Uso: app-info.sh ID   (o id do .desktop, sem a extensão)
# Saída: linhas "chave=valor" (version, developer, summary, url, package).
id=$1
[ -n "$id" ] || exit 0

file=""
for d in "$HOME/.local/share" $(printf '%s' "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr ':' ' ') /var/lib/flatpak/exports/share "$HOME/.local/share/flatpak/exports/share"; do
    if [ -f "$d/applications/$id.desktop" ]; then
        file="$d/applications/$id.desktop"
        break
    fi
done

# Pacote
if [ -n "$file" ] && command -v pacman >/dev/null; then
    real=$(readlink -f "$file")
    pkg=$(pacman -Qqo "$real" 2>/dev/null)
    if [ -n "$pkg" ]; then
        echo "package=$pkg"
        LANG=C pacman -Qi "$pkg" 2>/dev/null | sed -n 's/^Version *: \(.*\)/version=\1/p; s/^URL *: \(.*\)/url=\1/p'
    fi
fi
case "$file" in
    */flatpak/*)
        if command -v flatpak >/dev/null; then
            LANG=C flatpak info "$id" 2>/dev/null | sed -n 's/^ *Version: \(.*\)/version=\1/p'
        fi
        ;;
esac

# AppStream: o arquivo que declara este .desktop (ou tem o mesmo id).
meta=""
for d in /usr/share/metainfo /usr/share/appdata "$HOME/.local/share/metainfo"; do
    [ -d "$d" ] || continue
    meta=$(grep -l -e "<launchable type=\"desktop-id\">$id.desktop</launchable>" -e "<id>$id</id>" -e "<id>$id.desktop</id>" "$d"/*.xml 2>/dev/null | head -1)
    [ -n "$meta" ] && break
done
if [ -n "$meta" ]; then
    # Desenvolvedor: <developer><name>X</name> (novo) ou <developer_name>X (antigo).
    dev=$(tr '\n' ' ' < "$meta" | sed -n 's/.*<developer[^_>]*>[[:space:]]*<name[^>]*>\([^<]*\)<\/name>.*/\1/p' | head -1)
    [ -n "$dev" ] || dev=$(sed -n 's/.*<developer_name[^>]*>\([^<]*\)<\/developer_name>.*/\1/p' "$meta" | head -1)
    [ -n "$dev" ] && echo "developer=$dev"
    # Resumo em português, se houver; senão o padrão.
    sum=$(sed -n 's/.*<summary xml:lang="pt_BR">\([^<]*\)<\/summary>.*/\1/p; s/.*<summary xml:lang="pt">\([^<]*\)<\/summary>.*/\1/p' "$meta" | head -1)
    [ -n "$sum" ] || sum=$(sed -n 's/.*<summary>\([^<]*\)<\/summary>.*/\1/p' "$meta" | head -1)
    [ -n "$sum" ] && echo "summary=$sum"
fi
exit 0
