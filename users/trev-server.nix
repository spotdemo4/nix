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
      "direnv"
      "fish"
      "kitty"
      "starship"
    ];

  home.username = "trev";
  home.homeDirectory = "/home/trev";
  home.stateVersion = "24.05";

  # Create an alias for podman that selects the root socket
  home.shellAliases = {
    docker = "podman --url unix:///run/podman/podman.sock";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
