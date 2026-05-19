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
}
