{ ... }:
{
  # https://wiki.archlinux.org/title/Steam#Faster_shader_pre-compilation
  home.file.".steam/steam/steam_dev.cfg".text = ''
    unShaderBackgroundProcessingThreads 8
  '';
}
