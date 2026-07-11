{
  ...
}:
{
  imports = [
    ./server.nix
    ./opencode.nix
  ];

  trev.mcp.chromeHeadless = true;
}
