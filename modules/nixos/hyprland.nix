{ lib, config, pkgs, inputs, ... }:
 
{
  options.hyprland-nix = {
    enable = lib.mkEnableOption "enable hyprland";
  };

  config = lib.mkIf config.hyprland-nix.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    };
  };
}