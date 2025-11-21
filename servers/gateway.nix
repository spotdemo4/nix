{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (x: self + /modules/container/${x}.nix) [
    # Containers to import
    "portainer"
    "traefik"
  ];
}
