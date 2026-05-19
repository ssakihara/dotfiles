# dotfiles

`nix-darwin` + `home-manager` + Flakes で macOS の OS 設定・Homebrew パッケージ・ユーザー dotfile を宣言的に管理する。

## Installation

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ssakihara/dotfiles/main/install.sh)"
```

別ホスト名を使う場合は引数で指定:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ssakihara/dotfiles/main/install.sh)" -- mbp
```

事前に SSH 鍵を作成:

```sh
ssh-keygen -t ed25519 -C "example@example.com"
```

## Daily operations

すべての変更は `flake.nix` / `./nix/` 配下の編集 → 反映の流れで行う。

```sh
# 設定変更の反映
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)

# 入力 (nixpkgs / nix-darwin / home-manager) の更新
nix flake update

# 1 世代前にロールバック
sudo darwin-rebuild --rollback

# 世代一覧
sudo darwin-rebuild --list-generations

# 古い世代の削除
nix-collect-garbage -d
```

## Layout

```
.
├── flake.nix             # Flake エントリポイント
├── flake.lock
├── nix/
│   ├── darwin/
│   │   ├── default.nix   # nix-darwin 本体 (システム設定)
│   │   └── homebrew.nix  # nix-darwin の homebrew モジュール (brew / cask)
│   └── home/
│       └── default.nix   # home-manager 設定 (~/ 配下の dotfile)
├── claude/.claude/       # Claude Code 用 (stow 管理)
├── bin/.bin/             # 自作スクリプト (home-manager 配下)
├── git/                  # .gitconfig 系
├── zsh/                  # .zshrc / .zprofile
├── starship/             # starship.toml
├── ghostty/              # ghostty config
├── editorconfig/         # .editorconfig
├── mise/                 # mise config (mise 本体は brew)
├── install.sh            # 新規 mac 用ブートストラップ
└── macos.sh              # `defaults write` 系の macOS 設定
```

## Notes

- 言語ランタイム (Node.js / Ruby / Python) は `mise` / `rbenv` / `uv` で管理しており、nix 管理対象外。
- `~/.claude/` は Claude Code が動的に書き込むため stow のままにしている。
- nix-darwin の `homebrew` モジュールは Homebrew 本体をインストールしないため `/opt/homebrew` を再利用する。`install.sh` 内で Homebrew 本体のセットアップを先に行うようになっている。
