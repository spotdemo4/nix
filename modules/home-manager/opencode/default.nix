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

    xdg.configFile."opencode/plugins/auto-commit" = {
      source = ./plugins/auto-commit;
      recursive = true;
    };
    xdg.configFile."opencode/plugins/codex-usage" = {
      source = ./plugins/codex-usage;
      recursive = true;
    };
    xdg.configFile."opencode/plugins/direnv" = {
      source = ./plugins/direnv;
      recursive = true;
    };
    xdg.configFile."opencode/plugins/git-status" = {
      source = ./plugins/git-status;
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
