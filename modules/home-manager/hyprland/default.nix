{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    portalPackage = pkgs.trev.xdg-desktop-portal-hyprland;
    configType = "lua";
    extraConfig = builtins.readFile ./settings.lua;
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
