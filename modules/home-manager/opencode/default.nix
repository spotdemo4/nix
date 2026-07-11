{ ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
    commands.commit = ./commands/commit.md;
    skills = {
      ssh-bench = ./skills/ssh-bench.md;
      ssh-build = ./skills/ssh-build.md;
    };
  };

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
