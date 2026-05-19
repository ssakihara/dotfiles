{
  description = "ssakihara dotfiles (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
  let
    username = "s.sakihara";
  in {
    darwinConfigurations."ssakihara" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit username; };
      modules = [
        ./nix/darwin
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit username; };
          home-manager.users.${username} = import ./nix/home;
        }
      ];
    };
  };
}
