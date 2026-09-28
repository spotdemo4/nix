# trev's nix infra

[![check](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/check.yaml?branch=main&logo=github&logoColor=%23bac2de&label=check&labelColor=%23313244)](https://github.com/spotdemo4/nix/actions/workflows/check.yaml/)
[![vulnerable](https://img.shields.io/github/actions/workflow/status/spotdemo4/nix/vulnerable.yaml?branch=main&logo=github&logoColor=%23bac2de&label=vulnerable&labelColor=%23313244)](https://github.com/spotdemo4/nix/actions/workflows/vulnerable.yaml)

[![nixpkgs](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=nixpkgs&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/nixos/nixpkgs)
[![quadlet-nix](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=quadlet-nix&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/SEIAROTg/quadlet-nix)
[![determinate](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=determinate&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/DeterminateSystems/determinate)
[![home-manager](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=home-manager&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/nix-community/home-manager)
[![nur](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=nur&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/nix-community/NUR)
[![catppuccin](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=catppuccin&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/catppuccin/nix)
[![niks3](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=niks3&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/Mic92/niks3)
[![nix4vscode](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=nix4vscode&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/nix-community/nix4vscode)
[![trevpkgs](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=trevpkgs&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/spotdemo4/trevpkgs)
[![zen-browser](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=zen-browser&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/0xc000022070/zen-browser-flake)
[![agenix](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=agenix&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/ryantm/agenix)
[![trevbar](https://nix-shield.trev.zip/?url=https://raw.githubusercontent.com/spotdemo4/nix/refs/heads/main/flake.lock&input=trevbar&logoColor=%23bac2de&labelColor=%23313244&color=%235277C3)](https://github.com/spotdemo4/trevbar)

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
