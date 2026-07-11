{ self, ... }:
{
  imports = [
    (self + /modules/nixos/profiles/homelab-lxc.nix)
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

  home-manager.users.trev.imports = [
    (self + /modules/home-manager/profiles/trev/server.nix)
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.107";
  };
}
