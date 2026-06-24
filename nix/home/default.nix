{ pkgs, ... }:
{
  # home.username / home.homeDirectory は nix-darwin の users.users から自動取得

  # home-manager の互換性バージョン。初回設定後は変更しないこと
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.file.".editorconfig".source = ../../editorconfig/editorconfig;

  xdg.configFile."starship.toml".source = ../../starship/starship.toml;

  xdg.configFile."ghostty/config".source = ../../ghostty/config;

  home.file.".gitconfig".source = ../../git/gitconfig;
  home.file.".gitconfig_company".source = ../../git/gitconfig_company;
  home.file.".gitconfig_private".source = ../../git/gitconfig_private;
  home.file.".gitignore_global".source = ../../git/gitignore_global;

  home.file.".bin/git-aic" = {
    source = ../../bin/git-aic;
    executable = true;
  };
  home.file.".bin/git-cpr" = {
    source = ../../bin/git-cpr;
    executable = true;
  };
  home.file.".bin/git-sync-upstream" = {
    source = ../../bin/git-sync-upstream;
    executable = true;
  };

  # mise は <repo>/mise/config.toml を auto-discovery してしまうため、
  # リポジトリ側は global.toml にリネーム (配置先は ~/.config/mise/config.toml のまま)
  xdg.configFile."mise/config.toml".source = ../../mise/global.toml;

  home.file.".zshrc".source = ../../zsh/zshrc;
  home.file.".zprofile".source = ../../zsh/zprofile;
  home.file.".zsh_functions/ghw.zsh".source = ../../zsh/zsh_functions/ghw.zsh;

  # Claude Code: git 管理対象だけを symlink。
  # ~/.claude 自体は普通のディレクトリのまま残し、その配下に動的書き込み
  # (history.jsonl / sessions/ / projects/ など) が共存できるようにする。
  home.file.".claude/CLAUDE.md".source = ../../claude/CLAUDE.md;
  home.file.".claude/settings.json".source = ../../claude/settings.json;
  home.file.".claude/agents".source = ../../claude/agents;
  home.file.".claude/references".source = ../../claude/references;
  home.file.".claude/rules".source = ../../claude/rules;
  home.file.".claude/scripts".source = ../../claude/scripts;
  home.file.".claude/assets".source = ../../claude/assets;
}
