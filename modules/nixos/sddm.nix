{pkgs, ...}: {
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

  # Causes SDDM not to work btw
  # catppuccin.sddm = {
  #  enable = true;
  #  flavor = "mocha";
  # };
}
