{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprpaper
  ];

  xdg.configFile = {
    "hypr/hyprpaper.conf".text = ''
      preload = ~/Photos/wallpaper.jpg
      preload = /etc/nixos/static/fishy.png
      preload = /etc/nixos/static/fishy_vertical.png

      wallpaper = eDP-1,~/Photos/wallpaper.jpg
      wallpaper = desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,/etc/nixos/static/fishy.png
      wallpaper = desc:Dell Inc. S2719DGF 1HSYBY2,/etc/nixos/static/fishy_vertical.png

      ipc = off
    '';
  };
}
