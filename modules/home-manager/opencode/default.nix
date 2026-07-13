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
        "./plugins/auto-commit/status.tsx"
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
        [
          "./plugins/push/index.tsx"
          {
            gitBinary = lib.getExe pkgs.git;
          }
        ]
      ];
      agents.auto-committer = ./agents/auto-committer.md;
      skills = {
        ssh-bench = ./skills/ssh-bench.md;
        ssh-build = ./skills/ssh-build.md;
      };
    };

    xdg.configFile."opencode/plugins" = {
      source = ./plugins;
      recursive = true;
    };
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
