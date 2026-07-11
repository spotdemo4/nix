{ self, ... }:
{
  imports = [
    (self + /modules/nixos/profiles/homelab-lxc.nix)
  ]
  ++ map (c: self + /modules/nixos/${c}) [
    "tailscale"
  ]
  ++ map (c: self + /modules/container/${c}) [
    "monero"
    "portainer"
    "tor"
    "traefik"
  ];

  home-manager.users.trev.imports = [
    (self + /modules/home-manager/profiles/trev/server.nix)
  ];
}
