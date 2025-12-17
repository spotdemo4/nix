{ self, ... }:
let
  toImports = import (self + /modules/util/import);
in
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ toImports "container" [
    "bazarr"
    "discord-embedder"
    "overseerr"
    "plex"
    "portainer-agent"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "sabnzbd"
    "sonarr"
    "tautulli"
    "traefik-kop"
    "unpackerr"
  ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.107";
  };
}
