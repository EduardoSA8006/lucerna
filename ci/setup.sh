#!/usr/bin/env bash
# Prepara o container de um job do CI (roda como root): atualiza o keyring e o
# sistema, instala ci/packages/<job>.txt e garante um usuário comum (uid
# $CI_UID, 1000 por padrão) para rodar os checks. No smoke, tira a capability
# do sway: no container, sem isso, o exec falha com "Operation not permitted".
# No fim, limpa do cache do pacman o que não está instalado (o cache é guardado
# entre execuções, no GitHub e no volume do dev/ci.sh, e não pode crescer sem
# limite).
#   ci/setup.sh <lint|rules|unit|smoke>
set -euo pipefail

job=${1:?uso: ci/setup.sh <lint|rules|unit|smoke>}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
list="$here/packages/$job.txt"
[ -f "$list" ] || { echo "ERRO: não existe $list" >&2; exit 2; }

mapfile -t packages < <(grep -vE '^\s*(#|$)' "$list")
# O keyring primeiro: numa imagem velha, pacotes assinados por chaves novas
# falham na verificação da atualização completa.
pacman -Sy --noconfirm --needed archlinux-keyring
pacman -Syu --noconfirm --needed "${packages[@]}"

uid=${CI_UID:-1000}
getent passwd "$uid" > /dev/null || useradd -m -u "$uid" ci

if [ "$job" = smoke ]; then
    sway_bin=$(readlink -f "$(command -v sway)")
    if [ -n "$(getcap "$sway_bin")" ]; then
        setcap -r "$sway_bin"
    fi
fi

# O checkout do GitHub é do root; o usuário comum só precisa ler.
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    chmod -R a+rX "$GITHUB_WORKSPACE"
fi
if [ -n "${CI_OUT:-}" ]; then
    install -d -o "$uid" "$CI_OUT"
fi

pacman -Sc --noconfirm
