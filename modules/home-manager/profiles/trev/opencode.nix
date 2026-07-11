{
  inputs,
  self,
  ...
}:
{
  imports = [
    ./terminal.nix
  ]
  ++ map (module: self + /modules/home-manager/${module}) [
    "codex"
    "mcp"
    "opencode"
    "ssh"
  ];

  home.sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs.outPath}";
}
