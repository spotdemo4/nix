{ ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
    skills = {
      ssh-build = ./skills/ssh-build.md;
    };
  };

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
