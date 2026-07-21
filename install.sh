#!/bin/bash
set -euo pipefail

# 新規 Mac (Apple Silicon) 用の seed スクリプト。Homebrew と mise を導入し、
# dotfiles を clone して以降のセットアップを mise bootstrap に委譲する。
# 使い方: curl -fsSL https://raw.githubusercontent.com/ssakihara/dotfiles/main/install.sh | bash

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ssakihara/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/workspaces/github.com/ssakihara/dotfiles}"

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

error() {
  printf '\033[1;31mError:\033[0m %s\n' "$*" >&2
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew is already installed"
  else
    info "Installing Homebrew (Xcode Command Line Tools もあわせて導入される)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # 現行シェルに PATH を通す
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

clone_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    info "dotfiles already exist at $DOTFILES_DIR"
  else
    info "Cloning dotfiles into $DOTFILES_DIR"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    info "mise is already installed"
  else
    info "Installing mise"
    brew install mise
  fi
}

main() {
  if [ "$(uname)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
    error "this script supports macOS on Apple Silicon only"
    exit 1
  fi

  info "macOS 設定の一部には sudo パスワードが必要"

  install_homebrew
  clone_dotfiles
  install_mise

  cd "$DOTFILES_DIR"
  info "Running mise bootstrap"
  mise trust
  mise bootstrap

  info "Done. 新しいターミナルを開いて反映を確認すること"
}

# curl | bash で途中までしか読み込まれていない状態で実行が始まらないよう、main 呼び出しで括る
main "$@"
