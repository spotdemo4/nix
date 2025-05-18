{...}: {
  imports =
    [
      ../hosts/lxc/configuration.nix
    ]
    ++ map (x: ./../modules/nixos/${x}.nix) [
      # Programs to import
      "update"
    ];

  networking.hostName = "build";

  # Update script
  update = {
    enable = true;
    hostname = "build";
    user = "trev";
  };
}
