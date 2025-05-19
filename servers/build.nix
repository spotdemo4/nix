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
    ++ map (x: self + /modules/docker/${x}.nix) [
      # Docker containers to import
      "gitea-act-runner"
    ];

  networking.hostName = "build";

  # Update script
  update = {
    enable = true;
    hostname = "build";
    user = "trev";
  };
}
