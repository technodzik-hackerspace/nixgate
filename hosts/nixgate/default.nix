{ pkgs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./services/network.nix
    ./services/tailscale.nix
    ./services/acl.nix
    ./services/adguardhome.nix
    ./services/dnsmasq.nix
    ./services/netdata.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixgate";

  nixgate.network.wanInterface = "enp2s0";

  time.timeZone = "UTC";

  users.users.root.openssh.authorizedKeys.keys =
    (import ./secrets/ssh-keys.nix).root;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    git
  ];

  system.stateVersion = "24.11";

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" ];
    };
  };
}
