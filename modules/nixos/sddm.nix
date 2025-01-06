{ pkgs, ... }:
 
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  #catppuccin.sddm = {
  #  enable = true;
  #  flavor = "mocha";
  #};
}
