{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;

      wallpaper = [
        # Laptop
        {
          monitor = "eDP-1";
          path = "/etc/nixos/static/fishy_1080.png";
        }

        # Work
        {
          monitor = "desc:Samsung Electric Company S34J55x H4LT901888";
          path = "/etc/nixos/static/fishy_1440.png";
        }

        # Home
        {
          monitor = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. G34WQC A";
          path = "/etc/nixos/static/fishy_1440.png";
        }
        {
          monitor = "desc:Dell Inc. S2719DGF 1HSYBY2";
          path = "/etc/nixos/static/fishy_1080_vertical.png";
        }

        # HTPC
        {
          monitor = "desc:XXX Beyond TV 0x00010000";
          path = "/etc/nixos/static/fishy_2160.png";
        }

        # Default
        {
          monitor = "";
          path = "/etc/nixos/static/fishy_1080.png";
        }
      ];
    };
  };
}
