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

  xdg.configFile."opencode/plugins/commit-context.ts".source = ./plugins/commit-context.ts;

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
