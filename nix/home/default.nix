{ pkgs, ... }:
{
  # home.username / home.homeDirectory は nix-darwin の users.users から自動取得

  # home-manager の互換性バージョン。初回設定後は変更しないこと
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # dotfile の symlink 管理は mise.toml の [dotfiles] へ移管済み
}
