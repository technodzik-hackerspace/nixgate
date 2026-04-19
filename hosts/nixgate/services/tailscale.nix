{ config, lib, ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
  };

  # Trust tailscale interface — always allows SSH even if LAN firewall is broken
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
