# Laptop config
{self, ...}: {
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  # Power metrics
  services.upower.enable = true;
}
