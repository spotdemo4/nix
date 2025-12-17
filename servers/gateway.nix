{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "monerod"
    "p2pool"
    "portainer"
    "traefik"
  ];
}
