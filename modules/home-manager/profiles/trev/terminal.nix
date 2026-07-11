{
  self,
  ...
}:
{
  imports = [
    ./base.nix
  ]
  ++ map (module: self + /modules/home-manager/${module}) [
    "bat"
    "btop"
    "direnv"
    "eza"
    "fzf"
    "starship"
    "zoxide"
    "zsh"
  ];

  home.shellAliases.logs = "journalctl -b -e -u";
}
