#!/usr/bin/env bash
# Roda um job do CI como usuário comum, depois do ci/setup.sh. O ambiente é
# refeito do zero (env -i) com uma lista branca de variáveis, para nada herdado
# do runner do GitHub, do Docker ou da máquina mudar o resultado: o que passa no
# dev/ci.sh passa no GitHub, e vice-versa. A limpeza é guardada por um
# argumento interno (--inner), não por uma variável de ambiente: uma variável
# herdada com o mesmo nome pularia a limpeza sem que ninguém pedisse.
#   ci/run.sh <lint|rules|unit|smoke>
set -euo pipefail

if [ "${1:-}" = --inner ]; then
    inner=1
    job=${2:-}
else
    inner=0
    job=${1:-}
fi

case "$job" in
    lint | rules | unit | smoke) ;;
    *)
        echo "uso: ci/run.sh <lint|rules|unit|smoke>" >&2
        exit 2
        ;;
esac

if [ "$inner" = 0 ]; then
    home=$(getent passwd "$(id -u)" | cut -d: -f6)
    # A lista branca. Nenhum job precisa de outra: o unit fixa o próprio TZ, e o
    # lint, o unit e o smoke criam o próprio XDG_RUNTIME_DIR.
    keep=(
        HOME="${home:-/tmp}"
        PATH=/usr/local/bin:/usr/bin
        LANG=C.UTF-8
        LC_ALL=C.UTF-8
        TZ=UTC
        USER="$(id -un)"
        CI="${CI:-}"
        CI_OUT="${CI_OUT:-}"
        PYTHONDONTWRITEBYTECODE=1
    )
    exec env -i "${keep[@]}" bash "${BASH_SOURCE[0]}" --inner "$job"
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
echo "ambiente limpo: $(compgen -e | sort | tr '\n' ' ')"

case "$job" in
    lint) exec bash ci/lint.sh ;;
    rules)
        python3 -m unittest discover -s ci/tests -p 'test_*.py'
        exec python3 ci/rules.py
        ;;
    unit) exec bash ci/unit.sh ;;
    smoke) exec bash ci/smoke.sh ;;
esac
