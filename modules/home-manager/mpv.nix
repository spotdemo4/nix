{ lib, config, pkgs, ... }:
 
{
  programs.mpv = {
    enable = true;
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "sky";
    };
  };
}
