{
  inputs,
  self,
  ...
}:
{
  # Imports
  imports = map (x: self + /modules/home-manager/${x}) [
    "ssh"
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.05";

  home.sessionVariables = {
    NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
  };

  # https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
