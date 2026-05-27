{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    extraConfig = builtins.readFile ./settings.lua;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-luminous ];
    config.hyprland.default = [
      "hyprland"
      "luminous"
    ];
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
