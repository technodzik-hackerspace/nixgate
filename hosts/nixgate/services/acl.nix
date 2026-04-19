{ config, lib, ... }:

let
  cfg = config.nixgate.network;
  hosts = import ../secrets/hosts.nix;

  byAcl = group: builtins.filter (h: h.acl == group) hosts;
  ipsFor = group: map (h: h.ip) (byAcl group);
in
{
  options.nixgate.network.aclEnabled = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable per-device ACL firewall rules. When false, all devices get full internet access.";
  };

  config = lib.mkIf cfg.aclEnabled {
    networking.nftables.tables.acl = {
      family = "inet";

      content = ''
        set full_access {
          type ipv4_addr
          elements = { ${lib.concatStringsSep ", " (ipsFor "full")} }
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          ct state established,related accept

          # LAN-to-LAN is always allowed
          iifname "${cfg.lanInterface}" oifname "${cfg.lanInterface}" accept

          # Full-access devices can reach the internet
          iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" ip saddr @full_access accept
        }

        chain dns_redirect {
          type nat hook prerouting priority dstnat;

          # Force all LAN DNS through AdGuard Home
          iifname "${cfg.lanInterface}" udp dport 53 ip daddr != ${cfg.lanAddress} redirect to :53
          iifname "${cfg.lanInterface}" tcp dport 53 ip daddr != ${cfg.lanAddress} redirect to :53
        }
      '';
    };
  };
}