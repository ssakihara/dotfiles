#!/bin/bash

set -eu

WORKSPACES_DIR="${HOME}/workspaces/github.com/ssakihara"
DOTFILES_DIR="${WORKSPACES_DIR}/dotfiles"
HOST="${1:-$(scutil --get LocalHostName)}"

mkdir -p "${WORKSPACES_DIR}"

# 1. Xcode Command Line Tools
xcode-select --install 2>/dev/null || true

# 2. Homebrew (nix-darwin の homebrew モジュールは /opt/homebrew を再利用するため、本体は別途必要)
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. Nix (Determinate Installer)
if [ ! -e /nix/var/nix/profiles/default/bin/nix ]; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# 現在のシェルに nix を読み込む
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# 4. Flakes 有効化
mkdir -p "${HOME}/.config/nix"
if ! grep -q "experimental-features" "${HOME}/.config/nix/nix.conf" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "${HOME}/.config/nix/nix.conf"
fi

# 5. dotfiles を clone
if [ ! -d "${DOTFILES_DIR}" ]; then
    git clone https://github.com/ssakihara/dotfiles.git "${DOTFILES_DIR}"
fi
cd "${DOTFILES_DIR}"

# 6. nix-darwin で OS / packages / dotfile を一括適用
sudo nix run --extra-experimental-features "nix-command flakes" \
    nix-darwin -- switch --flake ".#${HOST}"

# 7. macOS 個別設定
sh ./macos.sh

# 8. 動的書き込みが多い ~/.claude は stow で配置
"$(/run/current-system/sw/bin/which stow || which stow)" -t ~ claude

echo ""
echo "Setup complete. Open a new terminal to load the updated environment."
