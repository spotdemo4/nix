{self, ...}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "minecraft"
      "portainer-agent"
      "traefik-kop"
      "whiteout"
    ];

  # Traefik mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.111";
  };
}
