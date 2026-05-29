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
  ++ map (x: self + /modules/home-manager/${x}) [
    "bat"
    "btop"
    "chromium"
    "codex"
    "continue"
    "cursor"
    "direnv"
    "discord"
    "eza"
    "fzf"
    "ghostty"
    "gpg"
    "gtk"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hyprshutdown"
    "kitty"
    "mako"
    "mods"
    "mpv"
    "qt"
    "starship"
    "steam"
    "vscode"
    "waybar"
    "wofi"
    "zed"
    "zen"
    "zoxide"
    "zsh"
  ];

  home.username = "trev";
  home.homeDirectory = "/home/trev";
  home.stateVersion = "24.05";

  home.sessionVariables = {
    NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
  };

  home.shellAliases = {
    codium = "code";
    logs = "journalctl -b -e -u";
    qc = "codex-commit";
    temp = "cd $(mktemp -d)";
    zed = "zeditor";
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
