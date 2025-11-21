{
  config,
  self,
  pkgs,
  ...
}:
{
  age.secrets."mods".file = self + /secrets/mods.age;
  age.secrets."mods".path = config.home.homeDirectory + "/.config/mods/mods.yml";

  home.packages = with pkgs; [
    mods
  ];
}
