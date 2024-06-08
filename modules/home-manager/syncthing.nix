{ lib, config, pkgs, ... }:
 
{
  options.syncthing-conf = {
    enable = lib.mkEnableOption "enable syncthing config";
  };

  config = lib.mkIf config.syncthing-conf.enable {
    services.syncthing = {
      enable = true;
    };
  };
}
