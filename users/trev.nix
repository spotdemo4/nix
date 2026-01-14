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
    "chromium"
    "continue"
    "cursor"
    "direnv"
    "discord"
    "eza"
    "fzf"
    "ghostty"
    "gpg"
    "gtk"
    "hyprland"
    "hyprpaper"
    "kitty"
    "mako"
    "mods"
    "mpv"
    "qt"
    "starship"
    "vscode"
    "waybar"
    "wofi"
    "zen"
    "zoxide"
    "zsh"
  ];

  home.username = "trev";
  home.homeDirectory = "/home/trev";
  home.stateVersion = "24.05";

  home.shellAliases = {
    temp = "cd $(mktemp -d)";
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
