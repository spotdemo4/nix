# Trev's NixOS Config

![check](https://github.com/spotdemo4/nix/actions/workflows/check.yaml/badge.svg?branch=main)
![vulnerable](https://github.com/spotdemo4/nix/actions/workflows/vulnerable.yaml/badge.svg?branch=main)

Flake-based NixOS config. Not really meant for public use except as a reference

## Install on NixOS

```bash
source /etc/set-environment &&
curl -s https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/scripts/init.sh |
bash -s (host | server)
```

[hosts](/hosts)
[servers](/servers)

## Bookmarks

- [nixos manual](https://nixos.org/manual/nixos/unstable/)
- [quadlet-nix](https://seiarotg.github.io/quadlet-nix/)
- [systemd.unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html)
- [podman-systemd.unit](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
