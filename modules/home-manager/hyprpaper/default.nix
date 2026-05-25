{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;

      wallpaper = [
        # Laptop Screen
        {
          monitor = "eDP-1";
          path = "/etc/nixos/static/fishy_2160.png";
        }

        # Office
        {
          monitor = "desc:Dell Inc. DELL S2725QS 4TYKT84";
          path = "/etc/nixos/static/fishy_2160.png";
        }
        {
          monitor = "desc:Philips Consumer Electronics Company PHL 221V8LB UK02442041972";
          path = "/etc/nixos/static/fishy_1080.png";
        }

        # Home
        {
          monitor = "desc:Dell Inc. DELL S2725QS 137GT84";
          path = "/etc/nixos/static/fishy_2160.png";
        }
        {
          monitor = "desc:Dell Inc. DELL S2725QS JGKHT84";
          path = "/etc/nixos/static/fishy_2160.png";
        }

        # TV
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
