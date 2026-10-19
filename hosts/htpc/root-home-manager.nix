{
  inputs,
  self,
  ...
}:
{
  imports = [
    (self + /modules/home-manager/ssh)
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "24.05";
    sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
  };

  trev.programs.ssh.enable = true;

  programs.home-manager.enable = true;
}
