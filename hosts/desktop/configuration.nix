# Desktop config
{self, ...}: {
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  # Scanner support
  hardware.sane = {
    enable = true;
    # brscan5.enable = true;
  };
}
