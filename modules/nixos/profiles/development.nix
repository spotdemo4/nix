{
  inputs,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    attic-client
    claude-code
    codex
    file
    jq
    mprocs
    nix-tree
    openssl
    ripgrep
    inputs.agenix.packages."${stdenv.hostPlatform.system}".default
  ];

  programs.nix-ld.enable = true;
}
