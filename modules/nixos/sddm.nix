{ pkgs, ... }:
 
{
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
  };

  catppuccin.sddm = {
    enable = true;
    flavor = "mocha";
  };
}