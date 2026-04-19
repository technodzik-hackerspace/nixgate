{ config, lib, ... }:

let
  cfg = config.nixgate.network;
  hosts = import ../hosts.nix;

  fullAccessIPs = map (h: h.ip) (builtins.filter (h: h.acl == "full") hosts);
  allowListGroups = builtins.filter (h: h.acl != "full" && h.acl != "lan") hosts;
in
{
  options.nixgate.network = {
    wanInterface = lib.mkOption {
      type = lib.types.str;
      description = "WAN-facing network interface (upstream/ISP)";
      example = "enp2s0";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp3s0";
      description = "LAN-facing network interface";
    };

    lanAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.42.42";
      description = "Static IP address for the LAN interface";
    };

    lanPrefixLength = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Subnet prefix length for the LAN interface";
    };
  };

  config = {
    boot.kernel.sysctl."net.ipv4.ip_forward" = "1";

    networking = {
      nftables.enable = true;
      useDHCP = false;

      interfaces.${cfg.wanInterface} = {
        useDHCP = true;
      };

      interfaces.${cfg.lanInterface} = {
        ipv4.addresses = [{
          address = cfg.lanAddress;
          prefixLength = cfg.lanPrefixLength;
        }];
      };

      nat = {
        enable = true;
        internalInterfaces = [ cfg.lanInterface ];
        externalInterface = cfg.wanInterface;
      };

      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 53 3000 ];
        allowedUDPPorts = [ 53 67 68 ];
      };
    };
  };
}
