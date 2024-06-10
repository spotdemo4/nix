{ lib, config, pkgs, ... }:
 
{
  options.mpv-conf = {
    enable = lib.mkEnableOption "enable mpv config";
  };

  config = lib.mkIf config.mpv-conf.enable {
    programs.mpv = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "mocha";
        accent = "sky";
      };
    };
  };
}
