{ config, lib, ... }:
{
  options.trev.programs.steam.enable = lib.mkEnableOption "Trev's Steam configuration";

  config = lib.mkIf config.trev.programs.steam.enable {
    # https://wiki.archlinux.org/title/Steam#Faster_shader_pre-compilation
    home.file.".steam/steam/steam_dev.cfg".text = ''
      unShaderBackgroundProcessingThreads 8
    '';
  };
}
