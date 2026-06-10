{ ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
  };

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
