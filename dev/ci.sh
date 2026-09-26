#!/usr/bin/env bash
# Roda os checks do CI na máquina local, no mesmo container do GitHub
# (archlinux:latest), com os mesmos scripts de ci/. Cada job roda num container
# próprio e descartável (lucerna-ci-<job>), com o cache do pacman num volume
# por job (lucerna-ci-pacman-<job>), como o cache por job do GitHub. Nenhum
# container de desenvolvimento (lucerna-dev, lucerna-polish) é tocado.
#   dev/ci.sh                 os quatro: lint, rules, unit, smoke
#   dev/ci.sh unit smoke      só esses
#   dev/ci.sh shell [job]     um bash no container do job (padrão: lint), com o
#                             repositório montado com escrita em /src; lá dentro,
#                             `bash ci/run.sh <job>` roda o job com o ambiente limpo
# Saída de cada job em ci-out/<job>/. Com LUCERNA_CI_PULL=0, não atualiza a imagem.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image=archlinux:latest

if [ "${LUCERNA_CI_PULL:-1}" != 0 ]; then
    docker pull -q "$image" > /dev/null || echo "aviso: não consegui atualizar $image; sigo com a cópia local" >&2
fi

# opts <job>: as opções do docker run comuns aos jobs, no array `common`.
opts() {
    common=(--user root -e CI=true -e CI_UID="$(id -u)" -e CI_OUT=/out -e CI_JOB="$1"
        -v "lucerna-ci-pacman-$1:/var/cache/pacman/pkg" -w /src)
}

if [ "${1:-}" = shell ]; then
    job=${2:-lint}
    mkdir -p "$repo/ci-out/$job"
    opts "$job"
    # shellcheck disable=SC2016 # as variáveis expandem dentro do container
    exec docker run --rm -it --name "lucerna-ci-shell" "${common[@]}" \
        -v "$repo:/src" -v "$repo/ci-out/$job:/out" "$image" \
        bash -c 'bash ci/setup.sh "$CI_JOB" && exec runuser -u "$(id -nu "$CI_UID")" -- bash'
fi

jobs=("$@")
[ ${#jobs[@]} -gt 0 ] || jobs=(lint rules unit smoke)
failed=()
for job in "${jobs[@]}"; do
    case "$job" in
        lint | rules | unit | smoke) ;;
        *)
            echo "job desconhecido: $job (use lint, rules, unit, smoke ou shell)" >&2
            exit 2
            ;;
    esac
    out="$repo/ci-out/$job"
    rm -rf "$out"
    mkdir -p "$out"
    echo "==> $job"
    opts "$job"
    # shellcheck disable=SC2016 # as variáveis expandem dentro do container
    if docker run --rm --name "lucerna-ci-$job" "${common[@]}" \
        -v "$repo:/src:ro" -v "$out:/out" "$image" \
        bash -c 'bash ci/setup.sh "$CI_JOB" && runuser -u "$(id -nu "$CI_UID")" -- bash ci/run.sh "$CI_JOB"'; then
        echo "==> $job: ok"
    else
        echo "==> $job: FALHOU (saída em ci-out/$job)"
        failed+=("$job")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo "falharam: ${failed[*]}"
    exit 1
fi
echo "todos passaram: ${jobs[*]}"
