# Desktop config
{self, ...}: {
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];
}
