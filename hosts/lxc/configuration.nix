# Config for every LXC server
{ self, ... }:
{
  imports = [
    (self + /hosts/server.nix)
    ./hardware-configuration.nix
  ];

  # Hostname mapping
  networking.hosts = {
    "10.10.10.105" = [
      "trev.xyz"
      "trev.zip"
      "trev.kiwi"
      "trev.rs"
      "cache.trev.zip"
      "s3.trev.zip"
      "nix.trev.zip"
    ];
  };

  # Upload journal to victoria logs
  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };
}
