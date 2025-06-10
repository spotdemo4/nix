{
  config,
  inputs,
  self,
  pkgs,
  ...
}: {
  age.secrets."quick-commit".file = self + /secrets/quick-commit.age;
  age.secrets."quick-commit".path = config.home.homeDirectory + "/.config/quick-commit.env";

  home.shellAliases = {
    qc = "quick-commit";
  };

  home.packages = [
    inputs.quick-commit.packages."${pkgs.system}".default
  ];
}
