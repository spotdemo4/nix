{ lib, config, pkgs, ... }:
 
{
  options.syncthing-nix = {
    enable = lib.mkEnableOption "enable syncthing config";
  };

  config = lib.mkIf config.syncthing-nix.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      settings = {
        devices = {
          "server" = {
            id = "5M4G6QU-FILKNI4-PL7LSZA-IQPDJMC-ETTQ4YB-53ZXVK6-B4GIXPC-SMBZEQV";
          };
        };
      };
    };
  };
}
