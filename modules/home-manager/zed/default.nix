{
  config,
  lib,
  pkgs,
  ...
}:
let
  projects = config.trev.projects;
  claude =
    lib.attrByPath
      [
        "trev"
        "programs"
        "claude"
      ]
      {
        enable = false;
        baseUrl = "https://proxy.trev.xyz";
        haikuModel = "gpt-5.6-luna";
        sonnetModel = "gpt-5.6-terra";
        opusModel = "gpt-5.6-sol";
        model = "gpt-5.6-sol";
      }
      config;
  claudeAgentAcp = pkgs.writeShellApplication {
    name = "claude-agent-acp";
    text = ''
      secret_path="''${XDG_RUNTIME_DIR}/agenix/cliproxyapi"

      if [[ ! -r "$secret_path" ]]; then
        printf 'Claude API token file is not readable: %s\n' "$secret_path" >&2
        exit 1
      fi

      ANTHROPIC_AUTH_TOKEN="$(<"$secret_path")"
      if [[ -z "$ANTHROPIC_AUTH_TOKEN" || "$ANTHROPIC_AUTH_TOKEN" == *$'\n'* ]]; then
        printf 'Claude API token must be a non-empty single line\n' >&2
        exit 1
      fi

      unset ANTHROPIC_API_KEY
      export ANTHROPIC_AUTH_TOKEN
      export ANTHROPIC_BASE_URL=${lib.escapeShellArg claude.baseUrl}
      export ANTHROPIC_CUSTOM_MODEL_OPTION=${lib.escapeShellArg claude.model}
      export ANTHROPIC_MODEL=${lib.escapeShellArg claude.model}
      export ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg claude.haikuModel}
      export ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg claude.opusModel}
      export ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg claude.sonnetModel}
      export CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg claude.model}

      exec ${lib.getExe pkgs.claude-agent-acp} "$@"
    '';
  };
  settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ./settings.json)) (
    {
      ssh_connections = [
        {
          host = projects.sshHost;
          nickname = projects.sshHost;
          projects = map (project: { paths = [ project.path ]; }) projects.entries;
        }
      ];
    }
    // lib.optionalAttrs claude.enable {
      agent_servers.claude-acp = {
        type = "custom";
        command = lib.getExe claudeAgentAcp;
        args = [ ];
        default_config_options = {
          mode = "bypassPermissions";
          model = claude.model;
          effort = "high";
        };
      };
    }
  );
in
{
  options.trev.programs.zed.enable = lib.mkEnableOption "Trev's Zed configuration";

  config = lib.mkIf config.trev.programs.zed.enable {
    programs.zed-editor = {
      enable = true;
      extensions = [
        "bash"
        "git-firefly"
        "gleam"
        "html"
        "ini"
        "kotlin"
        "log"
        "lua"
        "neocmake"
        "nix"
        "oxc"
        "proto"
        "ruff"
        "scss"
        "sql"
        "svelte"
        "tombi"
        "toml"
        "tsgo"
        "zig"
      ];
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;
      userSettings = settings;
      userKeymaps = builtins.fromJSON (builtins.readFile ./keymap.json);
      userTasks = builtins.fromJSON (builtins.readFile ./tasks.json);
      enableMcpIntegration = false;
    };

    # Zed Theme
    catppuccin.zed = {
      enable = true;
      accent = "sky";
      flavor = "mocha";
      italics = false;

      icons = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
