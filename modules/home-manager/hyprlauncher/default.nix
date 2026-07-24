{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.hyprlauncher.enable = lib.mkEnableOption "Trev's hyprlauncher configuration";

  config = lib.mkIf config.trev.programs.hyprlauncher.enable {
    home.packages = [ pkgs.hyprlauncher ];

    xdg.configFile."hypr/hyprlauncher.conf".text = ''
      ui {
        window_size = 500 325
      }
    '';

    xdg.configFile."hypr/hyprtoolkit.conf".text = ''
      background = rgba(0, 0, 0, 0.4)
      accent = rgba(33ccffee)
      accent_secondary = rgba(00ff99ee)
    '';
  };
}
