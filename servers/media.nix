{
  config,
  self,
  ...
}: {
  imports =
    [
      (self + /hosts/lxc/configuration.nix)
    ]
    ++ map (x: self + /modules/nixos/${x}.nix) [
      # Programs to import
      "update"
    ]
    ++ map (x: self + /modules/container/${x}.nix) [
      # Containers to import
      "portainer-agent"
      "traefik-kop"
    ];

  networking.hostName = "media";

  # Update script
  update = {
    enable = true;
    hostname = "media";
    user = "trev";
  };

  traefik-kop = {
    enable = true;
    ip = "10.10.10.107";
  };
}
