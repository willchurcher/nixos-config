{
  description = "NixOS + Home Manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    username = "will";
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Best practice: back up any pre-existing files that Home Manager takes over
          # e.g. ~/.config/user-dirs.dirs -> ~/.config/user-dirs.dirs.hm-backup
          home-manager.backupFileExtension = "hm-backup";

          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };
  };
}

