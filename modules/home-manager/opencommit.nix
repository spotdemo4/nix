{
  config,
  pkgs,
  self,
  ...
}: {
  age.secrets."opencommit".file = self + /secrets/opencommit.age;
  age.secrets."opencommit".path = config.home.homeDirectory + "/.opencommit";

  home.packages = with pkgs; [
    opencommit
  ];
}
