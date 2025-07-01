# Trev's Nix Flake

[![check status](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?logo=GitHub&logoColor=%23cdd6f4&label=check&labelColor=%2311111b)](https://github.com/spotdemo4/nix/actions/workflows/check.yaml)
[![flake status](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/flake.yaml?logo=nixos&logoColor=%2389dceb&label=flake&labelColor=%2311111b)](https://github.com/spotdemo4/nix/actions/workflows/flake.yaml)
[![nixos-unstable](https://img.shields.io/badge/nixos-unstable-%23313244?logo=nixos&logoColor=%2389dceb&labelColor=%2311111b)](https://nixos.org/)
[![cachix](https://img.shields.io/badge/cachix-trix-%23313244?logo=nixos&logoColor=%2389dceb&labelColor=%2311111b)](https://trix.cachix.org)

## Install on NixOS

```bash
source /etc/set-environment &&
curl -s https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/scripts/init.sh |
bash -s (host | server)
```
[hosts](/hosts)
[servers](/servers)