{ ... }:
 
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "trev";
    dataDir = "/home/trev";
    settings = {
      devices = {
        "server" = {
          id = "5M4G6QU-FILKNI4-PL7LSZA-IQPDJMC-ETTQ4YB-53ZXVK6-B4GIXPC-SMBZEQV";
        };
      };
      folders = {
        "/home/trev/Notes" = {
          id = "isqv7-pchjw";
          devices = [ "server" ];
        };
      };
    };
  };
}
