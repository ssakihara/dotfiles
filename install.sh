#!/bin/bash

set -eu

cd "${HOME}"

if ! type brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! type git >/dev/null 2>&1; then
    brew install git
fi

if [ ! -d dotfiles ]; then
    git clone https://github.com/ssakihara/dotfiles.git
fi

cd dotfiles

sh ./bootstrap.sh -f

sh ./brew.sh

sh ./macos.sh
