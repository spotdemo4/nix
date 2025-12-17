{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (x: self + /modules/container/${x}.nix) [
    "portainer"
  ]
  ++ map (x: self + /modules/container/${x}) [
    "traefik"
  ];
}
