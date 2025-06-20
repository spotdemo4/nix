# Trev's Nix Flake

![nixos-unstable](https://img.shields.io/badge/nixos-unstable-%2389dceb?logo=nixos&logoColor=%2389dceb&labelColor=%2311111b&link=https%3A%2F%2Fgithub.com%2Fnixos%2Fnixpkgs)
![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?logo=GitHub&logoColor=%23cdd6f4&label=check&labelColor=%2311111b&color=%2389dceb)
![last updated](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fspotdemo4%2Fnix%2Factions%2Fworkflows%2F157576189%2Fruns%3Fstatus%3Dcompleted%26conclusion%3Dsuccess%26per_page%3D1&query=%24.workflow_runs%5B0%5D.run_started_at&style=flat&logo=nixos&logoColor=%2389dceb&label=last%20updated&labelColor=%2311111b&color=%2389dceb)

## Install on NixOS

```bash
source /etc/set-environment &&
curl -s https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/scripts/init.sh |
bash -s (host | server)
```
[hosts](/hosts)
[servers](/servers)