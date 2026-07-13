{ pkgs, username, ... }:
{
  imports = [
    ./macos.nix
    ./ssh.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Nix 本体は Determinate / 公式インストーラ管理のため、nix-darwin に管理させない
  nix.enable = false;

  # nix-darwin の互換性バージョン。初回設定後は変更しないこと
  system.stateVersion = 5;

  # homebrew や system.defaults の所有者として扱うユーザー
  system.primaryUser = username;

  # Determinate Nix を明示的に許可
  ids.gids.nixbld = 30000;

  # home-manager が homeDirectory を取得するためにユーザー定義が必要
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # ~/.zprofile の `brew shellenv` が macOS の path_helper を呼び、
  # nix の PATH を消してしまう。/etc/zshrc が ~/.zprofile の後に読まれることを
  # 利用して、nix PATH を再度先頭に追加する
  environment.interactiveShellInit = ''
    export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"
  '';

  # sudo を Touch ID で認証可能にする (/etc/pam.d/sudo_local を生成)
  security.pam.services.sudo_local.touchIdAuth = true;
}
