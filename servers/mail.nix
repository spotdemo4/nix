{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports self "container" [
    "portainer-agent"
    "roundcube"
    "stalwart"
    "traefik-kop"
  ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.112";
  };
}
