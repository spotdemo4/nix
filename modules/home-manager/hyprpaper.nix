{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprpaper
  ];

  xdg.configFile = {
    "hypr/hyprpaper.conf".text = ''
      preload = ~/Photos/wallpaper.jpg
      preload = ~/Photos/fishy.png

      wallpaper = eDP-1,~/Photos/wallpaper.jpg
      wallpaper = desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,~/Photos/fishy.png

      unload unused

      ipc = off
    '';
  };
}
