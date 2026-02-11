{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "monero"
    "portainer"
    "tor"
    "traefik"
  ];
}
