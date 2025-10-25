# Trev's Nix Flake

[![check status](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?logo=GitHub&logoColor=%23cdd6f4&label=check&labelColor=%2311111b)](https://github.com/spotdemo4/nix/actions/workflows/check.yaml)
[![vulnerable status](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/vulnerable.yaml?logo=nixos&logoColor=%2389dceb&label=vulnerable&labelColor=%2311111b)](https://github.com/spotdemo4/nix/actions/workflows/vulnerable.yaml)
[![nixos-unstable](https://img.shields.io/badge/nixos-unstable-%23313244?logo=nixos&logoColor=%2389dceb&labelColor=%2311111b)](https://nixos.org/)

not really meant for public use except as a reference

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
