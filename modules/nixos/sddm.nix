{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "where_is_my_sddm_theme_qt5";
  };

  environment.systemPackages = [
    (pkgs.where-is-my-sddm-theme.override {
      variants = [ "qt5" ];
    })
  ];

  #catppuccin.sddm = {
  #  enable = true;
  #  flavor = "mocha";
  #};
}
