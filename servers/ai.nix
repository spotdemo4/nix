{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "context7"
    "discord-openrouter"
    "intel-gpu-exporter"
    "ollama"
    "portainer-agent"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.110";
  };

  intel-gpu-exporter = {
    enable = true;
    card = "card1";
    render = "renderD129";
  };

  # upload to victoria logs
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };
}
