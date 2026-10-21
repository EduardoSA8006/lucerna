#!/usr/bin/env bash
# Compila o lucernad (o daemon do Lucerna) numa revisão fixa do repositório e o
# instala em <prefixo>/bin/lucernad. Usado pelo dev/Dockerfile (o container de
# teste) e pelo ci/setup.sh (a fumaça), com a revisão de dev/lucernad.rev.
# A toolchain vem do rust-toolchain.toml do lucernad e as dependências, do
# Cargo.lock dele: o build é reproduzível. Se <prefixo>/rev já é <rev> e o
# binário existe, sai sem compilar (o cache do CI e do volume do dev/ci.sh).
# Precisa de rustup, git, gcc, clang, pkgconf e libpipewire.
#   dev/lucernad.sh <rev> <prefixo>
set -euo pipefail

rev=${1:?uso: dev/lucernad.sh <rev> <prefixo>}
prefix=${2:?uso: dev/lucernad.sh <rev> <prefixo>}

# Só um SHA completo: um branch ou uma tag mudam sem aviso, e o build deixa de
# ser reproduzível.
if ! [[ $rev =~ ^[0-9a-f]{40}$ ]]; then
    echo "dev/lucernad.sh: a revisão precisa ser um SHA de 40 caracteres hexadecimais, veio '$rev'" >&2
    exit 64
fi

if [ -x "$prefix/bin/lucernad" ] && [ "$(cat "$prefix/rev" 2> /dev/null)" = "$rev" ]; then
    echo "lucernad $rev já compilado em $prefix"
    exit 0
fi

src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git -C "$src" init -q
git -C "$src" fetch -q --depth 1 https://github.com/lucerna-desktop/lucernad.git "$rev"
git -C "$src" -c advice.detachedHead=false checkout -q FETCH_HEAD
# Sem argumentos, o rustup instala a toolchain do rust-toolchain.toml da pasta.
(cd "$src" && rustup toolchain install --profile minimal)
(cd "$src" && cargo build --release --locked --bin lucernad)
install -Dm755 "$src/target/release/lucernad" "$prefix/bin/lucernad"
printf '%s\n' "$rev" > "$prefix/rev"
echo "lucernad $rev instalado em $prefix"
