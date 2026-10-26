{ lib, pkgs, ... }:
# Netdata metrics for nixgate, streamed over Tailscale to a Netdata parent
# (dashboard there). No local web server.
#
# The stream key lives in secrets/netdata-stream.key (git-crypt) and must
# match a `[<key>]` section in the parent's stream.conf. It ends up in the
# Nix store.
#
# db mode = ram: history is kept in memory only (enough for the parent to
# backfill after a short disconnect), so the eMMC doesn't take a constant
# stream of metric writes.
let
  parent = "nas-yauhen-io.border-solfege.ts.net:19999";
  streamKey = lib.removeSuffix "\n" (builtins.readFile ../secrets/netdata-stream.key);
in
{
  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
    config = {
      web.mode = "none";
      db.mode = "ram";
    };
    configDir."stream.conf" = pkgs.writeText "stream.conf" (lib.generators.toINI { } {
      stream = {
        enabled = "yes";
        destination = parent;
        "api key" = streamKey;
      };
    });
  };

  # Logs tab on the parent: systemd-journal.plugin runs as netdata, and the
  # journal is root:systemd-journal 0640.
  users.users.netdata.extraGroups = [ "systemd-journal" ];
}
