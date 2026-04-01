{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.colloid-gtk-theme.override {
        tweaks = [ "catppuccin" ];
        colorVariants = [ "dark" ];
        themeVariants = [ "teal" ];
      };
      name = "Colloid-Teal-Dark-Catppuccin";
    };
    # https://raw.githubusercontent.com/nix-community/home-manager/f2d3e04e278422c7379e067e323734f3e8c585a7/modules/misc/news/2025/11/2025-11-26_11-55-28.nix
    gtk4.theme = null;
  };

  catppuccin.gtk.icon = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };
}
