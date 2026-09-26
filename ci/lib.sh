# shellcheck shell=bash
# Funções comuns aos scripts do CI. Carregue com:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
#   copy_repo <destino>
#       Copia o repositório (a pasta acima de ci/) para <destino>, que é criado
#       se não existir e fica gravável. Ficam de fora o .git e o ci-out. É a
#       cópia em que o qmllint (lint.sh), os testes de unidade e a cobertura
#       trabalham, para nunca escrever no repositório (no dev/ci.sh ele é montado
#       só leitura). Falha se <destino> não for informado ou se a cópia falhar.

# copy_repo <destino>: veja o topo do arquivo.
copy_repo() {
    local dest=${1:-} src entry
    if [ -z "$dest" ]; then
        echo "ERRO: copy_repo precisa da pasta de destino" >&2
        return 2
    fi
    src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || return 1
    mkdir -p "$dest" || return 1
    for entry in "$src"/* "$src"/.[!.]* "$src"/..?*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        case ${entry##*/} in
            .git | ci-out) continue ;;
        esac
        cp -R "$entry" "$dest/" || return 1
    done
    chmod -R u+w "$dest"
}
