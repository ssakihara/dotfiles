# dotfiles

`nix-darwin` + `home-manager` + Flakes で macOS の OS 設定・Homebrew パッケージ・ユーザー dotfile を宣言的に管理する。

## Setup (新規 Mac)

### 1. Xcode Command Line Tools

```sh
xcode-select --install
```

### 2. Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

インストール後、表示される Next steps に従って PATH を通す:

```sh
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

### 3. Nix (Determinate Installer)

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate
```

インストール後、新しいターミナルを開くか、以下を実行して現在のシェルに Nix を読み込む:

```sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 4. Flakes 有効化

```sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 5. dotfiles の clone と適用

```sh
mkdir -p ~/workspaces/github.com/ssakihara
git clone https://github.com/ssakihara/dotfiles.git ~/workspaces/github.com/ssakihara/dotfiles
cd ~/workspaces/github.com/ssakihara/dotfiles
nix run nix-darwin -- switch --flake .#default
```

## Daily operations

すべての変更は `flake.nix` / `./nix/` 配下の編集 → 反映の流れで行う。

```sh
# 設定変更の反映
darwin-rebuild switch --flake .#default

# 入力 (nixpkgs / nix-darwin / home-manager) の更新
nix flake update

# 1 世代前にロールバック
darwin-rebuild --rollback

# 世代一覧
darwin-rebuild --list-generations

# 古い世代の削除
nix-collect-garbage -d
```

## Layout

```
.
├── flake.nix             # Flake エントリポイント (username をここで一元定義)
├── flake.lock
├── nix/
│   ├── darwin/
│   │   ├── default.nix   # nix-darwin 本体 (システム設定 / users / 環境変数)
│   │   ├── homebrew.nix  # nix-darwin の homebrew モジュール (tap / brew / cask / mas)
│   │   ├── macos.nix     # `defaults` / `pmset` / DNS など macOS の挙動設定
│   │   └── ssh.nix       # ~/.ssh 権限正規化 / id_ed25519 自動生成
│   └── home/
│       └── default.nix   # home-manager 設定 (~/ 配下の dotfile を symlink)
├── claude/               # Claude Code の git 管理対象 (home-manager が ~/.claude/ に symlink)
├── bin/                  # 自作スクリプト (~/.bin/ 配下)
├── git/                  # gitconfig 系 (~/.gitconfig 等)
├── zsh/                  # zshrc / zprofile
├── starship/             # starship.toml
├── ghostty/              # ghostty config
├── editorconfig/         # editorconfig
├── mise/                 # mise config (mise 本体は brew)
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

- 言語ランタイム (Node.js / Ruby / Python) は `mise` / `rbenv` / `uv` で管理しており、nix 管理対象外。
- nix-darwin の `homebrew` モジュールは Homebrew 本体をインストールしないため `/opt/homebrew` を再利用する。Homebrew 本体は Setup 手順で事前にインストールしておくこと。
- `darwinConfigurations` のキーは Mac の LocalHostName ではなく `default` 固定にしている。`darwin-rebuild` を直接叩く場合も `.#default` を指定すること（`scutil --get LocalHostName` の値とは無関係）。
