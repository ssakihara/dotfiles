# dotfiles

`mise bootstrap` + Homebrew で macOS の OS 設定・パッケージ・ユーザー dotfile を宣言的に管理する。

## Setup (新規 Mac / Apple Silicon)

```sh
curl -fsSL https://raw.githubusercontent.com/ssakihara/dotfiles/main/install.sh | bash
```

`install.sh` が以下を順に行う:

1. Homebrew のインストール (Xcode Command Line Tools もあわせて導入される)
2. dotfiles の clone (`~/workspaces/github.com/ssakihara/dotfiles`)
3. mise のインストール (Homebrew 経由)
4. `mise trust` と `mise bootstrap` の実行

clone 先やリポジトリ URL は環境変数で上書きできる:

```sh
curl -fsSL https://raw.githubusercontent.com/ssakihara/dotfiles/main/install.sh | DOTFILES_DIR=~/src/dotfiles bash
```

すでに mise が入っているマシンでは、リポジトリ内で `mise bootstrap` を実行するだけで再セットアップできる。

`mise bootstrap` が以下を一括で行う:

- Homebrew formulae / tap のインストール (`[bootstrap.packages]`)
- cask のインストール (`homebrew/Brewfile` を post-packages hook で `brew bundle`)
- dotfile の symlink (`[dotfiles]`)
- macOS defaults の書き込み (`[bootstrap.macos.defaults]` + `scripts/macos-extra.sh`)
- CapsLock→Control リマップの launchd agent 登録
- SSH 鍵の初期生成と権限正規化 (`[tasks.bootstrap]`)

注意:

- `scripts/macos-extra.sh` が電源管理・DNS・Spotlight 停止のため sudo パスワードを要求する。
- 完了後は新しいターミナルを開いて反映を確認する。

### App Store アプリ (手動インストール)

App Store アプリは無料でも Apple アカウントへのサインインと入手時の認証が必須で、CLI (mas) も非公開 API 依存で自動化に不向きなため、宣言管理の対象外とする。
`mise bootstrap` 完了後、App Store から以下を手動でインストールする:

- [RunCat Neo](https://apps.apple.com/app/id6757801838)
- [Xcode](https://apps.apple.com/app/id497799835)

### Raycast 設定 (手動インポート)

Raycast は設定を暗号化 SQLite で保持しておりプレーンテキストでの宣言管理ができないため、`Export Settings & Data` コマンドのエクスポート (`raycast/Raycast.rayconfig`) をコミットして管理する。

- 新規 Mac: `mise bootstrap` 完了後 (Raycast は cask で導入済み)、`open raycast/Raycast.rayconfig` を実行してインポートする。
  エクスポート時に設定したパスフレーズの入力が必要 (リポジトリには含めない)。
- 設定変更時: Raycast で `Export Settings & Data` を実行し、出力ファイルで `raycast/Raycast.rayconfig` を上書きしてコミットする。

## Daily operations

すべての変更は `mise.toml` / `homebrew/Brewfile` / 各設定ファイルの編集 → `mise bootstrap` の流れで行う。

```sh
# 宣言と実マシンの差分確認 (差分があると非ゼロ終了)
mise bootstrap status --missing

# 宣言に合わせて全体を収束 (冪等なので何度でも実行可)
mise bootstrap

# 特定パートのみ適用 (packages / dotfiles / macos 等)
mise bootstrap --only packages

# formula の追加 (mise.toml の [bootstrap.packages] に追記して)
mise bootstrap packages apply

# cask の追加 (homebrew/Brewfile に追記して)
mise bootstrap --only packages

# 宣言から外したパッケージの削除 (手動運用)
mise bootstrap packages prune

# パッケージの一括アップグレード (手動運用)
mise bootstrap packages upgrade
```

dotfile は symlink でリポジトリ実体に直結しているため、リポジトリ内のファイル編集が即座に反映される（再適用は不要）。

## Layout

```
.
├── install.sh            # 新規 Mac 用 seed スクリプト (Homebrew/mise 導入 → mise bootstrap)
├── mise.toml             # bootstrap 定義のエントリポイント (packages / dotfiles / defaults / launchd / tasks)
├── homebrew/
│   └── Brewfile          # GUI アプリ (cask)。brew bundle で適用 (理由はファイル冒頭コメント参照)
├── scripts/
│   └── macos-extra.sh    # mise 非対応の macOS 設定 (array/dict/ByHost/sudo 系/killall)
├── claude/               # Claude Code の git 管理対象 (~/.claude/ 配下に個別 symlink)
├── bin/                  # 自作スクリプト (~/.bin/ 配下)
├── git/                  # gitconfig 系 (~/.gitconfig 等)
├── zsh/                  # zshrc / zprofile / zsh_functions
├── starship/             # starship.toml
├── ghostty/              # ghostty config
├── raycast/              # Raycast 設定のエクスポート (暗号化 .rayconfig。手動インポート)
├── editorconfig/         # editorconfig
├── mise/
│   └── global.toml       # mise グローバル設定 (~/.config/mise/config.toml へ symlink)
└── docs/                 # 補助ドキュメント
```

## Skills

```sh
gh skill install vercel-labs/agent-browser skills/agent-browser --agent claude-code --scope user
gh skill install cli/cli skills/gh --agent claude-code --scope user
gh skill install kepano/obsidian-skills skills/obsidian-bases --agent claude-code --scope user
gh skill install kepano/obsidian-skills skills/obsidian-cli --agent claude-code --scope user
gh skill install kepano/obsidian-skills skills/obsidian-markdown --agent claude-code --scope user
```

## Notes

- 言語ランタイム (Node.js / Ruby / Python) は `mise` / `rbenv` / `uv` で管理する。
  mise のグローバルツールは `mise/global.toml` の `[tools]` で宣言する。
- リポジトリ側のグローバル設定を `mise/config.toml` ではなく `global.toml` と命名しているのは、mise がリポジトリ内の `mise/config.toml` をローカル設定として auto-discovery してしまうため。
- cask を `[bootstrap.packages]` ではなく Brewfile で管理しているのは、mise (2026.7.5 時点) の cask 実装が brew でインストール済みの cask を認識できず、installer 型 cask にも非対応のため。
- `[bootstrap.macos.defaults]` の値は現在の Mac の `defaults read` から取得したものを反映している。
  mise で宣言できない設定 (array / dict / `-currentHost` / sudo が必要なもの) は `scripts/macos-extra.sh` に集約している。
