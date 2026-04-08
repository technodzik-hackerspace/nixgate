# nixgate

NixOS-based network gateway running on a ZimaBoard. Declarative DNS, DHCP, filtering, and network management — deployed with [Colmena](https://github.com/zhaofengli/colmena).

## What it does

- **DHCP** — dnsmasq with static leases defined in Nix
- **DNS filtering** — AdGuard Home with ad/tracker blocking and `.lan` rewrites
- **Disk management** — disko for declarative eMMC partitioning
- **Deployment** — Colmena for push-based NixOS deploys over SSH

## Hardware

ZimaBoard (Intel Celeron N3450, 8GB RAM, 29GB eMMC) with dual Realtek NICs.

## Structure

```
flake.nix                          # nixpkgs + disko inputs, colmena hive
hosts/nixgate/
├── default.nix                    # base NixOS config (SSH, firewall, packages)
├── disko.nix                      # eMMC partition layout (ESP + ext4 root)
├── hardware.nix                   # kernel modules, Intel microcode
├── hosts.nix                      # static host list (mac, ip, name) [encrypted]
└── services/
    ├── adguardhome.nix            # DNS filtering + .lan rewrites [encrypted]
    └── dnsmasq.nix                # DHCP server + static leases [encrypted]
```

Files marked `[encrypted]` contain network topology and are encrypted with [git-crypt](https://github.com/AGWA/git-crypt).

## Setup

### Prerequisites

- Nix with flakes enabled
- Colmena (`nix develop` provides it)
- git-crypt key (for encrypted files)

### Unlock secrets

```sh
git-crypt unlock
```

### Deploy

```sh
nix develop
colmena apply --on nixgate --impure
```

### Initial install (from scratch)

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#nixgate root@<ip>
```

## Secrets

Sensitive files (host MACs/IPs, network config) are encrypted with git-crypt. To add a collaborator:

```sh
git-crypt add-gpg-user <GPG_KEY_ID>
```
