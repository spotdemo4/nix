{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
  };

  # environment.systemPackages = [
  #   (pkgs.where-is-my-sddm-theme.override {
  #     variants = [ "qt5" ];
  #   })
  # ];

  catppuccin.sddm = {
   enable = true;
   flavor = "mocha";
  };
}
