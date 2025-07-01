# Config for every LXC server
{self, ...}: {
  imports = [
    (self + /hosts/server.nix)
    ./hardware-configuration.nix
  ];
}
