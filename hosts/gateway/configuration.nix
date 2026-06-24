{ self, ... }:
{
  imports = [
    (self + /templates/lxc)
    ./hardware-configuration.nix
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
}
