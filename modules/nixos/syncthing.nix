{ lib, config, pkgs, ... }:
 
{
  options.syncthing-nix = {
    enable = lib.mkEnableOption "enable syncthing config";
  };

  config = lib.mkIf config.syncthing-nix.enable {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
    };
  };
}
