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
      "prometheus"
    ];

  networking.hostName = "monitor";

  # Update script
  update = {
    enable = true;
    hostname = "monitor";
    user = "trev";
  };
}
