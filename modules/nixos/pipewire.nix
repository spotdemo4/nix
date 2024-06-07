{ lib, config, pkgs, ... }:
 
{
  options.pipewire-nix = {
    enable = lib.mkEnableOption "enable pipewire";
  };

  config = lib.mkIf config.pipewire-nix.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}