{...}: {
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
