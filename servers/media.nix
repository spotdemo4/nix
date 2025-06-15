{self, ...}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "portainer-agent"
      "traefik-kop"
      "radarr"
      "sonarr"
      "minecraft"
    ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.107";
  };
}
