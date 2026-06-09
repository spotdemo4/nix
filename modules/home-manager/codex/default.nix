{ ... }:
{
  programs.codex = {
    enable = true;
    settings = fromTOML (builtins.readFile ./config.toml);
    enableMcpIntegration = true;
  };
}
