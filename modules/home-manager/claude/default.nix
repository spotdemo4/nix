{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.programs.claude;
  claudeRuntimeInputs = [
    pkgs.direnv
    pkgs.gh
    pkgs.nodejs_24
    pkgs.python3
  ];
  direnvHook = {
    hooks = [
      {
        type = "command";
        command = ''${lib.getExe pkgs.direnv} export bash > "$CLAUDE_ENV_FILE"'';
      }
    ];
  };
  claudePackage = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = claudeRuntimeInputs;
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
      export ANTHROPIC_BASE_URL=${lib.escapeShellArg cfg.baseUrl}
      export ANTHROPIC_CUSTOM_MODEL_OPTION=${lib.escapeShellArg cfg.model}
      export ANTHROPIC_DEFAULT_FABLE_MODEL=${lib.escapeShellArg cfg.fableModel}
      export ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg cfg.haikuModel}
      export ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg cfg.opusModel}
      export ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg cfg.sonnetModel}
      export CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg cfg.subagentModel}

      # Backticks in the model identity guidance are literal, not command substitutions.
      # shellcheck disable=SC2016
      exec ${lib.getExe cfg.package} \
        --model ${lib.escapeShellArg cfg.model} \
        --append-system-prompt ${lib.escapeShellArg config.programs.claude-code.context} \
      "$@"
    '';
  };
  claudeAgentAcpPackage = pkgs.writeShellApplication {
    name = "claude-agent-acp";
    runtimeInputs = claudeRuntimeInputs;
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
      export ANTHROPIC_BASE_URL=${lib.escapeShellArg cfg.baseUrl}
      export ANTHROPIC_CUSTOM_MODEL_OPTION=${lib.escapeShellArg cfg.model}
      export ANTHROPIC_MODEL=${lib.escapeShellArg cfg.model}
      export ANTHROPIC_DEFAULT_FABLE_MODEL=${lib.escapeShellArg cfg.fableModel}
      export ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg cfg.haikuModel}
      export ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg cfg.opusModel}
      export ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg cfg.sonnetModel}
      export CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg cfg.subagentModel}

      exec ${lib.getExe pkgs.claude-agent-acp} "$@"
    '';
  };
in
{
  options.trev.programs.claude = {
    enable = lib.mkEnableOption "Claude Code wrapper using CLIProxyAPI";

    package = lib.mkPackageOption pkgs "claude-code" { };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://proxy.trev.xyz";
      description = "CLIProxyAPI endpoint used by Claude Code.";
    };

    haikuModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-haiku-4-5-20251001";
      description = "Model used when Claude Code selects Haiku.";
    };

    sonnetModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-sonnet-5";
      description = "Model used when Claude Code selects Sonnet.";
    };

    opusModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-opus-5-5";
      description = "Model used when Claude Code selects Opus.";
    };

    fableModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-fable-5-1";
      description = "Model used when Claude Code selects Fable.";
    };

    subagentModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-6-luna";
      description = "Default model used by Claude Code subagents, independently of the model aliases.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "claude-opus-5-5";
      description = "Default model used by Claude Code.";
    };

    contextWindowTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 272000;
      description = "Context window Claude Code assumes for models routed through CLIProxyAPI.";
    };

    autoCompactWindowTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 258400;
      description = "Context capacity Claude Code uses for auto-compaction calculations.";
    };

    maxOutputTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 128000;
      description = "Maximum output tokens Claude Code requests and reserves before auto-compaction.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.maxOutputTokens < cfg.contextWindowTokens;
        message = "trev.programs.claude.maxOutputTokens must be smaller than contextWindowTokens.";
      }
      {
        assertion = cfg.autoCompactWindowTokens <= cfg.contextWindowTokens;
        message = "trev.programs.claude.autoCompactWindowTokens must not exceed contextWindowTokens.";
      }
    ];

    age.secrets.cliproxyapi.file = self + /secrets/cliproxyapi.age;

    home.packages = [
      claudeAgentAcpPackage
      claudePackage
    ];

    programs.claude-code = {
      enable = true;
      package = null;
      enableMcpIntegration = true;

      context = ''
        You run inside Claude Code through CLIProxyAPI, which serves both Anthropic Claude and OpenAI GPT models. Claude Code is the host application, not your model identity.

        Use the current runtime model ID to identify yourself, for example from "You are powered by the model <model-id>." When asked which model you are, answer with that exact model ID. After a /model switch, use the updated runtime model information rather than the startup default or earlier responses.

        A runtime model ID starting with `claude-` identifies an Anthropic Claude model; one starting with `gpt-` identifies an OpenAI GPT model. Either provider may be active. Do not infer model identity from the Claude Code name, tool names, API format, alias labels, or previous responses. If no reliable runtime model ID is provided, say that the model identity is unknown instead of guessing.
      '';

      settings = {
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };
        effortLevel = "high";
        enableWorkflows = true;
        feedbackDrafts = "off";
        fallbackModel = [
          "gpt-6-sol"
          "gpt-6-luna"
        ];
        hooks = {
          CwdChanged = [ direnvHook ];
          SessionStart = [ direnvHook ];
        };
        modelPicker.options = [
          {
            model = "gpt-6-astra";
            label = "GPT-6 Astra";
            description = "OpenAI GPT-6 Astra via CLIProxyAPI";
          }
          {
            model = "gpt-6-sol";
            label = "GPT-6 Sol";
            description = "OpenAI GPT-6 Sol via CLIProxyAPI";
          }
          {
            model = "gpt-6-luna";
            label = "GPT-6 Luna";
            description = "OpenAI GPT-6 Luna via CLIProxyAPI";
          }
        ];
        permissions.defaultMode = "bypassPermissions";
        skillOverrides."claude-api" = "off";
        workflowSizeGuideline = "medium";
        env = {
          CLAUDE_CODE_AUTO_COMPACT_WINDOW = toString cfg.autoCompactWindowTokens;
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
          CLAUDE_CODE_MAX_RETRIES = "15";
          CLAUDE_CODE_MAX_CONTEXT_TOKENS = toString cfg.contextWindowTokens;
          CLAUDE_CODE_MAX_OUTPUT_TOKENS = toString cfg.maxOutputTokens;
        };
      };
    };
  };
}
