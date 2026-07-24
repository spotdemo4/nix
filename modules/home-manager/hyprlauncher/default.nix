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

    xdg.configFile."hypr/hyprtoolkit.conf".text = ''
      accent = rgba(33ccffee)
      accent_secondary = rgba(00ff99ee)
    '';
  };
}
