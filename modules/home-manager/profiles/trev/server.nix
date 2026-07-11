{
  ...
}:
{
  imports = [
    ./terminal.nix
  ];

  home.shellAliases.docker = "podman --url unix:///run/podman/podman.sock";
}
