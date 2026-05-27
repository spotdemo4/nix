{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    portalPackage = (pkgs.callPackage ./xdg-desktop-portal.nix { });
    configType = "lua";
    extraConfig = builtins.readFile ./settings.lua;
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
