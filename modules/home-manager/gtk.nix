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

    catppuccin = {
      icon = {
        enable = true;
        accent = "sky";
        flavor = "mocha";
      };
    };
  };
}