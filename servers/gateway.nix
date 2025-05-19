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
      "traefik"
      "portainer"
      "authelia"
    ];

  networking.hostName = "gateway";

  # Update script
  update = {
    enable = true;
    hostname = "gateway";
    user = "trev";
  };
}
