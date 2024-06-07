{ lib, config, pkgs, ... }:
 
{
  options.hyprpaper-conf = {
    enable = lib.mkEnableOption "enable hyprpaper config";
  };

  config = lib.mkIf config.hyprpaper-conf.enable {
    xdg.configFile = {
      "hypr/hyprpaper.conf".text = ''
        preload = ~/Photos/wallpaper.jpg
        wallpaper = eDP-1,~/Photos/wallpaper.jpg

        ipc = off
      '';
    };
  };
}
