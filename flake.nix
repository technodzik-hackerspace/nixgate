{
  description = "nixgate — NixOS network gateway on ZimaBoard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }: let
    conf = import ./hosts/nixgate/secrets/config.nix;
  in {
    nixosConfigurations.nixgate = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nixgate
      ];
    };

    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      };

      nixgate = { name, nodes, pkgs, ... }: {
        deployment = {
          targetHost = conf.gatewayAddress;
          targetUser = "root";
        };

        imports = [
          disko.nixosModules.disko
          ./hosts/nixgate
        ];
      };
    };

    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in pkgs.mkShell {
      packages = [
        pkgs.colmena
        pkgs.nixos-anywhere
      ];
    };
  };
}
