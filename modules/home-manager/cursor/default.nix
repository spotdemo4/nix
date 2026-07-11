{ config, lib, ... }:
{
  options.trev.programs.cursor.enable = lib.mkEnableOption "Trev's cursor configuration";

  config = lib.mkIf config.trev.programs.cursor.enable {
    catppuccin.cursors = {
      enable = true;
      accent = "dark";
      flavor = "mocha";
    };

    home.pointerCursor = {
      enable = true;
      size = 22;
    };

    # for hyprland
    home.sessionVariables = {
      HYPRCURSOR_SIZE = 22;
      HYPRCURSOR_THEME = "catppuccin-dark-mocha-cursors";
    };
  };
}
