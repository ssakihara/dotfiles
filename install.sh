#!/bin/bash

set -eu

cd "${HOME}"

if ! type brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew install git stow volta uv

if [ ! -d dotfiles ]; then
    git clone https://github.com/ssakihara/dotfiles.git
fi

cd dotfiles

sh ./bootstrap.sh

sh ./brew.sh

volta install node@24
volta install pnpm

uv python install --default 3.14

sh ./macos.sh
