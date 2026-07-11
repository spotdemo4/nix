{
  inputs,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.agenix.homeManagerModules.default
  ];

  home = {
    username = "trev";
    homeDirectory = "/home/trev";
    stateVersion = "24.05";
  };

  catppuccin = {
    enable = true;
    autoEnable = false;
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  programs.home-manager.enable = true;
}
