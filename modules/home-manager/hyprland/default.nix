{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;

    configType = "lua";
    extraConfig = builtins.readFile ./settings.lua;
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
