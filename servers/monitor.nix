{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ (toImports self "container" [
    "grafana"
    "portainer-agent"
    "traefik-kop"
    "victoria-metrics"
  ]);

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.109";
  };
}
