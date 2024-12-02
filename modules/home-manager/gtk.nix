{ pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.magnetic-catppuccin-gtk.override {
        accent = ["teal"];
        shade = "dark";
      };
      name = "Catppuccin-GTK";
    };
    iconTheme = {
      package = pkgs.tela-icon-theme;
      name = "Tela";
    };
  };
}