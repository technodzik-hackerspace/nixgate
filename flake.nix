{
  description = "nixgate — NixOS network gateway on ZimaBoard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Netdata only (services/netdata.nix): the parent nags about outdated
    # agents, and bumping the main nixpkgs moves the whole gateway. Update
    # just this with `nix flake update nixpkgs-netdata`.
    nixpkgs-netdata.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, disko, nixpkgs-netdata, ... }: let
    conf = import ./hosts/nixgate/secrets/config.nix;
    netdataPkgs = { _module.args.netdataPkgs = import nixpkgs-netdata { system = "x86_64-linux"; }; };
  in {
    nixosConfigurations.nixgate = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        netdataPkgs
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
          netdataPkgs
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
