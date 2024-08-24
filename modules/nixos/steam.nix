{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    extraPackages = [
      pkgs.gamescope
    ];
  };
}