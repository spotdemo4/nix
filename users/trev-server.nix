{
  inputs,
  self,
  ...
}: {
  # Imports
  imports =
    [
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
    # Create an alias for podman that selects the root socket
    docker = "podman --url unix:///run/podman/podman.sock";
    logs = "journalctl -b -e -u";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
