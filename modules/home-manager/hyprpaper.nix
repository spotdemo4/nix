{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";

      preload = [
        "/etc/nixos/static/fishy_1080.png"
        "/etc/nixos/static/fishy_1080_vertical.png"
        "/etc/nixos/static/fishy_1440.png"
        "/etc/nixos/static/fishy_2160.png"
      ];

      wallpaper = [
        # Laptop
        "eDP-1,/etc/nixos/static/fishy_1080.png"

        # Work
        "desc:Samsung Electric Company S34J55x H4LT901888,/etc/nixos/static/fishy_1440.png"

        # Home
        "desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A 23072B001686,/etc/nixos/static/fishy_1440.png"
        "desc:Dell Inc. S2719DGF 1HSYBY2,/etc/nixos/static/fishy_1080_vertical.png"
        "desc:XXX Beyond TV 0x00010000,/etc/nixos/static/fishy_2160.png"
      ];
    };
  };
}
