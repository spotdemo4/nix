{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.trev.programs.opencode.enable = lib.mkEnableOption "Trev's OpenCode configuration";

  config = lib.mkIf config.trev.programs.opencode.enable {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = builtins.fromJSON (builtins.readFile ./config.json);
      tui.plugin = [
        [
          "./plugins/git-status/index.tsx"
          {
            gitBinary = lib.getExe pkgs.git;
            fetchMs = 60000;
          }
        ]
        [
          "./plugins/codex-usage/index.tsx"
          {
            codexBinary = lib.getExe config.programs.codex.package;
            refreshMs = 30000;
          }
        ]
      ];
      agents.auto-committer = ./agents/auto-committer.md;
      commands.push = ./commands/push.md;
      skills = {
        ssh-bench = ./skills/ssh-bench.md;
        ssh-build = ./skills/ssh-build.md;
      };
    };

    xdg.configFile."opencode/plugins/auto-commit/index.ts".source = ./plugins/auto-commit/index.ts;
    xdg.configFile."opencode/plugins/direnv/index.ts".source = ./plugins/direnv/index.ts;
    xdg.configFile."opencode/plugins/codex-usage/index.tsx".source = ./plugins/codex-usage/index.tsx;
    xdg.configFile."opencode/plugins/git-status/core.ts".source = ./plugins/git-status/core.ts;
    xdg.configFile."opencode/plugins/git-status/index.tsx".source = ./plugins/git-status/index.tsx;
    xdg.configFile."opencode/package.json" = {
      force = true;
      source = ./package.json;
    };
    xdg.configFile."opencode/bun.lock" = {
      force = true;
      source = ./bun.lock;
    };

    catppuccin.opencode = {
      enable = true;
      flavor = "mocha";
    };
  };
}
