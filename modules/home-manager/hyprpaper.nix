{ ... }:

{
  xdg.configFile = {
    "hypr/hyprpaper.conf".text = ''
      preload = ~/Photos/wallpaper.jpg
      wallpaper = eDP-1,~/Photos/wallpaper.jpg

      ipc = off
    '';
  };
}
