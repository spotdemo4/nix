{...}: {
  imports = [
    ../hosts/lxc/configuration.nix
  ];

  networking.hostName = "build";

  # Update script
  update = {
    enable = true;
    hostname = "build";
    user = "trev";
  };

  # Auto update
  updater = {
    enable = true;
  };
}
