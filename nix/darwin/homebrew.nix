{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      # 初期段階は手動運用に近づけるため自動更新/アップグレードを無効化
      autoUpdate = false;
      upgrade = false;
      # 宣言外を勝手に消さない。Phase 移行が安定したら "zap" に上げる
      cleanup = "none";
    };

    # global.brewfile は将来 brew bundle dump との互換のため残す
    global.brewfile = true;

    taps = [
      "coderabbitai/tap"
      "hashicorp/tap"
      "homebrew/bundle"
      "leoafarias/fvm"
    ];

    brews = [
      "agent-browser"
      "bat"
      "broot"
      "cloud-sql-proxy"
      "cloudflared"
      "detect-secrets"
      "eza"
      "fd"
      "ffmpeg"
      "fzf"
      "genact"
      "gh"
      "ghq"
      "git"
      "git-delta"
      "git-filter-repo"
      "helm"
      "hey"
      "icu4c@76"
      "jq"
      "k6"
      "kubernetes-cli"
      "lefthook"
      "libmagic"
      "libpq"
      "mas"
      "mise"
      "neovim"
      "nkf"
      "openjdk@21"
      "pkgconf"
      "python@3.12"
      "ruby-build"
      "rbenv"
      "starship"
      "the_silver_searcher"
      "uv"
      "watch"
      "yazi"
      "yq"
      "zplug"
      "coderabbitai/tap/git-gtr"
      "hashicorp/tap/terraform"
      "leoafarias/fvm/fvm"
    ];

    casks = [
      "appcleaner"
      "bitwarden"
      "copilot-cli"
      "dbeaver-community"
      "docker-desktop"
      "font-hack-nerd-font"
      "font-hackgen"
      "font-hackgen-nerd"
      "gcloud-cli"
      "ghostty"
      "google-japanese-ime"
      "imageoptim"
      "obsidian"
      "raycast"
      "visual-studio-code"
    ];

    masApps = {
      RunCat = 1429033973;
      Xcode = 497799835;
    };
  };
}
