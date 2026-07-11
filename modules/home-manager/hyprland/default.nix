{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.hyprland.enable = lib.mkEnableOption "Trev's Hyprland configuration";

  config = lib.mkIf config.trev.programs.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      extraConfig = builtins.readFile ./settings.lua;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        trev.xdg-desktop-portal-luminous
      ];
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.RemoteDesktop" = "luminous";
        "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
      };
    };

    home.packages = with pkgs; [
      brightnessctl
    ];
  };
}
