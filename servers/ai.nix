{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ (toImports self "container" [
    "context7"
    "discord-openrouter"
    "intel-gpu-exporter"
    "ollama"
    "portainer-agent"
    "traefik-kop"
  ]);

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.110";
  };

  intel-gpu-exporter = {
    enable = true;
    card = "card1";
    render = "renderD129";
  };
}
