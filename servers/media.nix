{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "bazarr"
    "discord-embedder"
    "seerr"
    "plex"
    "portainer/agent.nix"
    "prowlarr"
    "qbittorrent"
    "radarr"
    "sabnzbd"
    "sonarr"
    "tautulli"
    "traefik-kop"
    "unpackerr"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.107";
  };
}
