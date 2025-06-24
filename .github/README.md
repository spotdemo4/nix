# Trev's Nix Flake

[![nixos-unstable](https://img.shields.io/badge/nixos-unstable-%23313244?logo=nixos&logoColor=%2389dceb&labelColor=%2311111b)](https://nixos.org/)
[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?logo=GitHub&logoColor=%23cdd6f4&label=check&labelColor=%2311111b)](https://github.com/spotdemo4/nix/actions/workflows/check.yaml)
[![last-update](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fspotdemo4%2Fnix%2Factions%2Fworkflows%2F157576189%2Fruns%3Fstatus%3Dcompleted%26conclusion%3Dsuccess%26per_page%3D1&query=%24.workflow_runs%5B0%5D.run_started_at&style=flat&logo=nixos&logoColor=%2389dceb&label=last%20updated&labelColor=%2311111b&color=%23313244)](https://github.com/spotdemo4/nix/actions/workflows/update.yaml)

## Install on NixOS

```bash
source /etc/set-environment &&
curl -s https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/scripts/init.sh |
bash -s (host | server)
```
[hosts](/hosts)
[servers](/servers)