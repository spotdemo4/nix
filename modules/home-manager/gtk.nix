{ pkgs, config, ... }:
{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.trev.catppuccin-gtk.override {
        themeVariants = [ "sky" ];
        colorVariants = [ "dark" ];
      };
      name = "Catppuccin-Sky-Dark";
    };

    # https://raw.githubusercontent.com/nix-community/home-manager/f2d3e04e278422c7379e067e323734f3e8c585a7/modules/misc/news/2025/11/2025-11-26_11-55-28.nix
    gtk4.theme = config.gtk.theme;
  };

  catppuccin.gtk.icon = {
    enable = true;
    accent = "sky";
    flavor = "mocha";
  };
}
