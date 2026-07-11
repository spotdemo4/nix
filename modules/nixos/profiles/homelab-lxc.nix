{
  self,
  ...
}:
{
  imports = [
    ./server.nix
    ../platforms/proxmox-lxc.nix
  ];

  networking.hosts = {
    "10.10.10.105" = [
      "trev.xyz"
      "trev.zip"
      "trev.kiwi"
      "trev.rs"
      "cache.trev.zip"
      "s3.trev.zip"
      "nix.trev.zip"
      "niks3.trev.zip"
    ];
  };

  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://10.10.10.109:9428/insert/journald";
  };
}
