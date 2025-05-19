{
  config,
  pkgs,
  inputs,
  self,
  ...
}: {
  # Imports
  imports =
    [
      inputs.catppuccin.homeModules.catppuccin
    ]
    ++ map (x: self + /modules/home-manager/${x}.nix) [
      # Home Manager modules to import
      "direnv"
      "kitty"
      "starship"
      "zsh"
    ];

  home.username = "trev";
  home.homeDirectory = "/home/trev";

  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
