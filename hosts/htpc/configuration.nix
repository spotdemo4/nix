# HTPC config
{
  inputs,
  self,
  pkgs,
  ...
}: {
  imports = [
    (self + /hosts/client.nix)
    ./hardware-configuration.nix
  ];

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        user = "trev";
        command = "hyprland";
      };
      default_session = {
        user = "trev";
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd hyprland";
      };
    };
  };

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs self;
    };
    users = {
      trev = {
        imports = [(self + /users/trev.nix)];
        wayland.windowManager.hyprland.settings.exec-once = [
          "nm-applet --indicator"
          "blueman-applet"
          "steam"
        ];
      };
    };
  };
}
