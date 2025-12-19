{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "anubis"
    "cobalt"
    "portainer-agent"
    "shlink"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.114";
  };

  # upload to victoria Logs
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };
}
