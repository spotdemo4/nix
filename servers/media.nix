{self, ...}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
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
