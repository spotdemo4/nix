{
  config,
  lib,
  self,
  pkgs,
  ...
}:
{
  options.trev.programs.mods.enable = lib.mkEnableOption "Trev's mods configuration";

  config = lib.mkIf config.trev.programs.mods.enable {
    age.secrets."mods".file = self + /secrets/mods.age;
    age.secrets."mods".path = config.home.homeDirectory + "/.config/mods/mods.yml";

    home.packages = with pkgs; [
      mods
    ];
  };
}
