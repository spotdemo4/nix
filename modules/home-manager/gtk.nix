{ pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.colloid-gtk-theme.override {
        tweaks = ["catppuccin"];
        colorVariants = ["dark"];
        themeVariants = ["teal"];
      };
      name = "Colloid-Teal-Dark-Catppuccin";
    };
    iconTheme = {
      package = pkgs.colloid-icon-theme.override {
        schemeVariants = ["catppuccin"];
        colorVariants = ["teal"];
      };
      name = "Colloid-Teal-Catppuccin-Dark";
    };
  };
}