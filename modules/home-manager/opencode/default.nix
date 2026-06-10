{ ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./settings.json);
  };

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
