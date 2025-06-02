{...}: {
  # home.packages = with pkgs; [
  #   hyprpaper
  # ];

  # xdg.configFile = {
  #   "hypr/hyprpaper.conf".text = ''
  #     preload = ~/Photos/wallpaper.jpg
  #     preload = /etc/nixos/static/fishy.png
  #     preload = /etc/nixos/static/fishy_vertical.png

  #     wallpaper = eDP-1,~/Photos/wallpaper.jpg
  #     wallpaper = desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,/etc/nixos/static/fishy.png
  #     wallpaper = desc:Dell Inc. S2719DGF 1HSYBY2,/etc/nixos/static/fishy_vertical.png

  #     ipc = off
  #   '';
  # };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";

      preload = [
        "/etc/nixos/static/fishy.png"
        "/etc/nixos/static/fishy1080.png"
        "/etc/nixos/static/fishy_vertical.png"
      ];

      wallpaper = [
        #Laptop
        "eDP-1,/etc/nixos/static/fishy1080.png"

        #Work
        "desc:Samsung Electric Company S34J55x H4LT901888,/etc/nixos/static/fishy.png"

        # Home
        "desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,/etc/nixos/static/fishy.png"
        "desc:Dell Inc. S2719DGF 1HSYBY2,/etc/nixos/static/fishy_vertical.png"
      ];
    };
  };
}
