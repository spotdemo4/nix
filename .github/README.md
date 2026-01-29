# trev's nix infra

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/nix/actions/workflows/check.yaml/)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/nix/actions/workflows/vulnerable.yaml)
[![nix](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fspotdemo4%2Fnix%2Frefs%2Fheads%2Fmain%2Fflake.lock&query=%24.nodes.nixpkgs_2.original.ref&logo=nixos&logoColor=%23bac2de&label=channel&labelColor=%23313244&color=%234d6fb7)](https://nixos.org/)

flake-based NixOS config

not really meant for public use except as a reference

## install

```bash
source /etc/set-environment &&
curl -s https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/scripts/init.sh |
bash -s (host | server)
```

[hosts](/hosts)
[servers](/servers)

## bookmarks

- [nixos](https://nixos.org/manual/nixos/unstable/)
- [nixpkgs](https://search.nixos.org/packages)
- [home-manager](https://home-manager-options.extranix.com/?query=&release=master)
- [quadlet-nix](https://seiarotg.github.io/quadlet-nix/)
- [systemd.unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html)
- [podman-systemd.unit](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
