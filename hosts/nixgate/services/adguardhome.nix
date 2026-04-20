{ config, pkgs, lib, ... }:

let
  hosts = import ../secrets/hosts.nix;
  creds = import ../secrets/creds.nix;
  conf = import ../secrets/config.nix;
  dnsRewrites = map (h: { domain = "${h.name}.lan"; answer = h.ip; }) hosts;

  staticLeases = map (h: {
    expires = "";
    ip = h.ip;
    hostname = h.name;
    mac = h.mac;
    static = true;
  }) hosts;

  leasesJson = pkgs.writeText "leases.json" (builtins.toJSON {
    version = 1;
    leases = staticLeases;
  });
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "0.0.0.0";
    port = conf.adguardhome.port;

    settings = {
      users = [ creds.adguard ];

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = conf.dns.upstream;
        bootstrap_dns = conf.dns.bootstrap;
        protection_enabled = true;
        filtering_enabled = true;
      };

      dhcp = {
        enabled = true;
        interface_name = config.nixgate.network.lanInterface;
        local_domain_name = "lan";
        dhcpv4 = {
          gateway_ip = config.nixgate.network.lanAddress;
          subnet_mask = conf.dhcp.subnet_mask;
          range_start = conf.dhcp.range_start;
          range_end = conf.dhcp.range_end;
          lease_duration = 43200; # 12h in seconds
        };
      };

      filtering = {
        rewrites = dnsRewrites;
      };
    };
  };

  # Seed static leases before AdGuard Home starts — it ignores static_leases in YAML
  systemd.services.adguardhome.preStart = lib.mkAfter ''
    DATA_DIR="/var/lib/AdGuardHome/data"
    mkdir -p "$DATA_DIR"
    cp --force ${leasesJson} "$DATA_DIR/leases.json"
    chmod 644 "$DATA_DIR/leases.json"
  '';

  services.resolved.enable = false;

  networking.firewall.allowedTCPPorts = [ conf.adguardhome.port 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
