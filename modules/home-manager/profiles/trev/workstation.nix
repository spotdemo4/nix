{
  self,
  ...
}:
{
  imports = [
    ./opencode.nix
  ]
  ++ map (module: self + /modules/home-manager/${module}) [
    "chromium"
    "continue"
    "cursor"
    "discord"
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
    "steam"
    "vscode"
    "waybar"
    "wofi"
    "zed"
    "zen"
  ];

  home.shellAliases = {
    codium = "code";
    qc = "codex-commit";
    temp = "cd $(mktemp -d)";
    zed = "zeditor";
  };
}
