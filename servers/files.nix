{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "attic"
    "copyparty"
    "immich"
    "portainer-agent"
    "traefik-kop"
    "versitygw"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.113";
  };
}
