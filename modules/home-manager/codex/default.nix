{ ... }:
{
  programs.codex = {
    enable = true;
    settings = fromTOML (builtins.readFile ./settings.toml);
  };
}
