{
  inputs,
  self,
  ...
}:
{
  # Imports
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.agenix.homeManagerModules.default
  ]
  ++ map (x: self + /modules/home-manager/${x}.nix) [
    # Home Manager modules to import
    "bat"
    "btop"
    "eza"
    "fzf"
    "direnv"
    "starship"
    "zoxide"
    "zsh"
  ];

  home.username = "trev";
  home.homeDirectory = "/home/trev";
  home.stateVersion = "24.05";

  home.shellAliases = {
    docker = "podman --url unix:///run/podman/podman.sock"; # selects the root socket
    logs = "journalctl -b -e -u";
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
