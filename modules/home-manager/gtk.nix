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
      package = pkgs.tela-icon-theme;
      name = "Tela";
    };
  };
}