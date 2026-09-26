# shellcheck shell=bash
# Funções comuns aos scripts do CI. Carregue com:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# O contrato da cópia do repositório, o mesmo para o qmllint (Tarefa 7), os
# testes de unidade (Tarefa 8), a cobertura (Tarefa 16) e a fumaça (Tarefa 18):
# todo script que copia o repositório usa a copy_repo, e todo script que lista
# arquivos do repositório usa a repo_files, para a cópia e a lista verem os
# mesmos arquivos e nada que só existe na máquina local (o que o .gitignore
# lista) mudar o resultado em relação ao GitHub.
#
#   REPO_EXCLUDES
#       Pastas que ficam de fora, em qualquer nível: o .git, a saída do CI e o
#       que o .gitignore lista como pasta. O .git sai por nome, qualquer que
#       seja o tipo: num git worktree ou submódulo ele é um arquivo (gitdir: …).
#   REPO_EXCLUDE_FILES
#       Arquivos que ficam de fora, em qualquer nível (padrões do find -name):
#       os gerados que o .gitignore lista.
#   repo_files <raiz>
#       Os arquivos (e links) de <raiz>, sem os de cima, com caminho relativo
#       (./pasta/arquivo), separados por NUL. Pastas não entram na lista: uma
#       pasta vazia não é copiada (como no GitHub, onde o git não guarda pasta
#       vazia).
#   copy_repo <destino>
#       Copia os arquivos da repo_files do repositório (a pasta acima de ci/)
#       para <destino>, que é criado se não existir e fica gravável: o script
#       trabalha na cópia e nunca escreve no repositório (no dev/ci.sh ele é
#       montado só leitura). Falha se <destino> não for informado ou se a cópia
#       falhar.

REPO_EXCLUDES=(.git ci-out .superpowers .cache __pycache__ .ruff_cache)
REPO_EXCLUDE_FILES=('*.qmlc' '*.jsc' .qmlls.ini)

# repo_files <raiz>: veja o topo do arquivo.
repo_files() {
    local root=${1:-} name
    local -a dirs=(-false) files=(-false)
    if [ -z "$root" ]; then
        echo "ERRO: repo_files precisa da raiz" >&2
        return 2
    fi
    for name in "${REPO_EXCLUDES[@]}"; do dirs+=(-o -name "$name"); done
    for name in "${REPO_EXCLUDE_FILES[@]}"; do files+=(-o -name "$name"); done
    (cd "$root" && find . -mindepth 1 \( -name .git -o -type d \( "${dirs[@]}" \) \) -prune \
        -o -not -type d -not \( "${files[@]}" \) -print0)
}

# copy_repo <destino>: veja o topo do arquivo.
copy_repo() {
    local dest=${1:-} src
    local -a st
    if [ -z "$dest" ]; then
        echo "ERRO: copy_repo precisa da pasta de destino" >&2
        return 2
    fi
    src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || return 1
    mkdir -p "$dest" && dest=$(cd "$dest" && pwd) || return 1
    repo_files "$src" | (cd "$src" && xargs -0 -r cp -P --parents -t "$dest")
    st=("${PIPESTATUS[@]}")
    if [ "${st[0]}" -ne 0 ] || [ "${st[1]}" -ne 0 ]; then
        echo "ERRO: copy_repo não conseguiu copiar o repositório para $dest" >&2
        return 1
    fi
    chmod -R u+w "$dest"
}
