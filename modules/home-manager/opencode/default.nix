{ config, lib, ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./config.json);
    tui.plugin = [
      [
        "./plugins/codex-usage.tsx"
        {
          codexBinary = lib.getExe config.programs.codex.package;
          refreshMs = 30000;
        }
      ]
    ];
    agents.auto-committer = ./agents/auto-committer.md;
    skills = {
      ssh-bench = ./skills/ssh-bench.md;
      ssh-build = ./skills/ssh-build.md;
    };
  };

  xdg.configFile."opencode/plugins/auto-commit.ts".source = ./plugins/auto-commit.ts;
  xdg.configFile."opencode/plugins/codex-usage.LICENSE".source = ./plugins/codex-usage.LICENSE;
  xdg.configFile."opencode/plugins/codex-usage.tsx".source = ./plugins/codex-usage.tsx;
  xdg.configFile."opencode/package.json" = {
    force = true;
    source = ./package.json;
  };

  catppuccin.opencode = {
    enable = true;
    flavor = "mocha";
  };
}
