{
  description = "nixgate — NixOS network gateway on ZimaBoard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Netdata only (services/netdata.nix): the parent nags about outdated
    # agents, and bumping the main nixpkgs moves the whole gateway. Pinned to
    # a nixpkgs master commit whose netdata is in cache.nixos.org (channels lag);
    # same pin as ~/git/fl and ~/git/nixie — bump the rev in all three.
    nixpkgs-netdata.url = "github:NixOS/nixpkgs/39e1731dcac1f235c7aec665556d4ace5a1fa7fd";
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
