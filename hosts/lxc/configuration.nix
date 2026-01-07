# Config for every LXC server
{ self, ... }:
{
  imports = [
    (self + /hosts/server.nix)
    ./hardware-configuration.nix
  ];

  networking.hosts = {
    "10.10.10.105" = [
      "trev.xyz"
      "trev.zip"
      "trev.kiwi"
      "trev.rs"
      "cache.trev.zip"
    ];
  };
}
