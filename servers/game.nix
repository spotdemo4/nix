{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "minecraft"
    "portainer-agent"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.111";
  };

  # upload to victoria logs
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };
}
