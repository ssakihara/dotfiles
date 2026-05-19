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
│   │   ├── homebrew.nix  # nix-darwin の homebrew モジュール (brew / cask)
│   │   └── macos.nix     # `defaults` / `pmset` / DNS など macOS の挙動設定
│   └── home/
│       └── default.nix   # home-manager 設定 (~/ 配下の dotfile)
├── claude/.claude/       # Claude Code 用 (stow 管理)
├── bin/                  # 自作スクリプト (~/.bin/ へ home-manager 配下)
├── git/                  # gitconfig 系 (~/.gitconfig 等へ)
├── zsh/                  # zshrc / zprofile
├── starship/             # starship.toml
├── ghostty/              # ghostty config
├── editorconfig/         # editorconfig
├── mise/                 # mise config (mise 本体は brew)
└── install.sh            # 新規 mac 用ブートストラップ
```

## Notes

- 言語ランタイム (Node.js / Ruby / Python) は `mise` / `rbenv` / `uv` で管理しており、nix 管理対象外。
- `~/.claude/` は実ディレクトリ。動的書き込みファイル (history.jsonl / sessions/ / projects/ など) はそのまま配置し、git 管理対象 (CLAUDE.md / agents/ / rules/ など) のみ home-manager で symlink している。
- nix-darwin の `homebrew` モジュールは Homebrew 本体をインストールしないため `/opt/homebrew` を再利用する。`install.sh` 内で Homebrew 本体のセットアップを先に行うようになっている。
