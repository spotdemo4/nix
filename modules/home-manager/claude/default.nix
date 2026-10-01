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
  ]
  ++ lib.optional (config.trev.mcp.enable or false) (
    pkgs.callPackage ./forgejo-pr-wait { tokenFile = config.trev.mcp.forgejoTokenFile; }
  );
  claudeRuntimePath = lib.makeBinPath claudeRuntimeInputs;
  direnvHook = {
    hooks = [
      {
        type = "command";
        # Reloading direnv restores the PATH from before the inherited DIRENV_DIFF,
        # which drops the wrapper runtime inputs, so append them again.
        command = ''
          {
            ${lib.getExe pkgs.direnv} export bash
            printf '\ncase ":$PATH:" in *:%s:*) ;; *) export PATH="$PATH:%s" ;; esac\n' ${claudeRuntimePath} ${claudeRuntimePath}
          } > "$CLAUDE_ENV_FILE"
        '';
      }
    ];
  };
  # Merged with host definitions via mkDefault so single fields can be overridden.
  defaultModels = {
    "claude-haiku-4-5-20251001".alias = "haiku";
    "claude-sonnet-5-5" = {
      alias = "sonnet";
      effort = "high";
      context1m = true;
    };
    "claude-opus-5-5" = {
      alias = "opus";
      effort = "high";
      context1m = true;
    };
    "claude-fable-5-1" = {
      alias = "fable";
      effort = "high";
      context1m = true;
    };
    "gpt-6-astra" = {
      label = "GPT-6 Astra";
      description = "OpenAI GPT-6 Astra via CLIProxyAPI";
      order = 1;
    };
    "gpt-6-sol" = {
      label = "GPT-6 Sol";
      description = "OpenAI GPT-6 Sol via CLIProxyAPI";
      order = 2;
    };
    "gpt-6-luna" = {
      label = "GPT-6 Luna";
      description = "OpenAI GPT-6 Luna via CLIProxyAPI";
      order = 3;
    };
  };
  aliasedModels = lib.filterAttrs (_: model: model.alias != null) cfg.models;
  pickerModels = lib.sortOn (model: model.order) (
    lib.mapAttrsToList (id: model: model // { inherit id; }) (
      lib.filterAttrs (_: model: model.alias == null) cfg.models
    )
  );
  # Claude Code cannot verify 1M support behind a gateway, so opt in with the [1m] suffix.
  # The `or` keeps unknown IDs evaluable until the unknownModels assertion reports them.
  modelId = id: id + lib.optionalString (cfg.models.${id}.context1m or false) "[1m]";
  modelAliases = lib.mapAttrsToList (_: model: model.alias) aliasedModels;
  # Each skills/<name>.md becomes the /<name> skill.
  skillFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
    builtins.readDir ./skills
  );
  skills = lib.mapAttrs' (
    name: _: lib.nameValuePair (lib.removeSuffix ".md" name) (./skills + "/${name}")
  ) skillFiles;
  unknownModels = lib.filter (id: !(cfg.models ? ${id})) (
    [
      cfg.model
      cfg.subagentModel
    ]
    ++ cfg.fallbackModels
  );
  modelEnv = {
    ANTHROPIC_BASE_URL = cfg.baseUrl;
    ANTHROPIC_CUSTOM_MODEL_OPTION = cfg.resolvedModel;
    CLAUDE_CODE_MAX_CONTEXT_TOKENS = toString cfg.contextWindowTokens;
    CLAUDE_CODE_SUBAGENT_MODEL = modelId cfg.subagentModel;
  }
  // lib.mapAttrs' (
    id: model: lib.nameValuePair "ANTHROPIC_DEFAULT_${lib.toUpper model.alias}_MODEL" (modelId id)
  ) aliasedModels;
  mkClaudeWrapper =
    {
      name,
      env ? { },
      exec,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        # Appended so project devshells and system profiles take priority.
        export PATH="$PATH:${claudeRuntimePath}"

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
        ${lib.concatLines (
          lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") (modelEnv // env)
        )}
        ${exec}
      '';
    };
  claudePackage = mkClaudeWrapper {
    name = "claude";
    exec = ''
      # Backticks in the model identity guidance are literal, not command substitutions.
      # shellcheck disable=SC2016
      exec ${lib.getExe cfg.package} \
        --model ${lib.escapeShellArg cfg.resolvedModel} \
        --append-system-prompt ${lib.escapeShellArg config.programs.claude-code.context} \
        "$@"
    '';
  };
  claudeAgentAcpPackage = mkClaudeWrapper {
    name = "claude-agent-acp";
    env.ANTHROPIC_MODEL = cfg.resolvedModel;
    exec = ''exec ${lib.getExe pkgs.claude-agent-acp} "$@"'';
  };
  # Talks to Anthropic directly with the /login subscription, for when CLIProxyAPI is down.
  claudeLocalPackage = pkgs.writeShellApplication {
    name = "claude-local";
    text = ''
      export PATH="$PATH:${claudeRuntimePath}"

      # Drop gateway variables inherited from a proxied session.
      unset ${
        lib.concatStringsSep " " (
          lib.attrNames modelEnv
          ++ [
            "ANTHROPIC_API_KEY"
            "ANTHROPIC_AUTH_TOKEN"
            "ANTHROPIC_MODEL"
          ]
        )
      }

      # The shared settings fall back to models only CLIProxyAPI serves.
      exec ${lib.getExe cfg.package} \
        --settings ${
          lib.escapeShellArg (
            builtins.toJSON {
              fallbackModel = cfg.localFallbackModels;
              modelPicker.options = [ ];
            }
          )
        } \
        "$@"
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

    models = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              alias = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "haiku"
                    "sonnet"
                    "opus"
                    "fable"
                  ]
                );
                default = null;
                description = "Claude Code model alias this model serves. Aliased models are listed by Claude Code itself, so they are left out of the model picker.";
              };

              label = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Model picker label.";
              };

              description = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Model picker description.";
              };

              order = lib.mkOption {
                type = lib.types.int;
                default = 0;
                description = "Model picker sort key; ties are sorted by model ID.";
              };

              effort = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.enum [
                    "low"
                    "medium"
                    "high"
                    "xhigh"
                    "max"
                  ]
                );
                default = null;
                description = "Default effort level for this model, or null to leave it to Claude Code.";
              };

              context1m = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether this Claude model has a 1M token context window. Claude Code assumes 200K for Claude models behind a gateway unless the model ID carries the [1m] suffix this adds.";
              };
            };
          }
        )
      );
      default = { };
      description = "Models served through CLIProxyAPI, keyed by model ID.";
    };

    subagentModel = lib.mkOption {
      type = lib.types.str;
      default = "claude-sonnet-5-5";
      description = "Default model used by Claude Code subagents, independently of the model aliases.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "claude-opus-5-5";
      description = "Default model used by Claude Code.";
    };

    resolvedModel = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = modelId cfg.model;
      defaultText = lib.literalMD "`model` with the `[1m]` suffix when its `context1m` is set";
      description = "Model ID Claude Code is launched with.";
    };

    fallbackModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "gpt-6-sol"
        "gpt-6-luna"
      ];
      description = "Models Claude Code falls back to, in order, when the selected model is unavailable.";
    };

    localFallbackModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "sonnet" ];
      description = "Models claude-local falls back to, in order. Without CLIProxyAPI, aliases resolve to Claude Code's built-in models.";
    };

    contextWindowTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 272000;
      description = "Context window Claude Code assumes for non-Claude models, such as GPT models routed through CLIProxyAPI. Claude models use their own window; see context1m.";
    };

    maxOutputTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 128000;
      description = "Maximum output tokens Claude Code requests. Auto-compaction reserves at most 20K of it.";
    };
  };

  config = lib.mkIf cfg.enable {
    trev.programs.claude.models = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) defaultModels;

    assertions = [
      {
        assertion = cfg.maxOutputTokens < cfg.contextWindowTokens;
        message = "trev.programs.claude.maxOutputTokens must be smaller than contextWindowTokens.";
      }
      {
        assertion = unknownModels == [ ];
        message = "trev.programs.claude references models missing from trev.programs.claude.models: ${lib.concatStringsSep ", " (lib.unique unknownModels)}.";
      }
      {
        assertion = lib.allUnique modelAliases;
        message = "trev.programs.claude.models must not assign the same alias to more than one model.";
      }
    ];

    age.secrets.cliproxyapi.file = self + /secrets/cliproxyapi.age;

    home.packages = [
      claudeAgentAcpPackage
      claudeLocalPackage
      claudePackage
    ];

    programs.claude-code = {
      enable = true;
      package = null;
      enableMcpIntegration = true;
      inherit skills;

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
        fallbackModel = map modelId cfg.fallbackModels;
        hooks = {
          CwdChanged = [ direnvHook ];
          SessionStart = [ direnvHook ];
        };
        modelPicker.options = map (
          model:
          {
            model = modelId model.id;
            inherit (model) label;
          }
          // lib.optionalAttrs (model.description != null) { inherit (model) description; }
        ) pickerModels;
        # Newer models ignore the top-level user effortLevel, so pin it per model.
        modelSettings = lib.mapAttrs (_: model: { effortLevel = model.effort; }) (
          lib.filterAttrs (_: model: model.effort != null) cfg.models
        );
        permissions.defaultMode = "bypassPermissions";
        skillOverrides."claude-api" = "off";
        workflowSizeGuideline = "medium";
        env = {
          CLAUDE_CODE_MAX_RETRIES = "15";
          CLAUDE_CODE_MAX_OUTPUT_TOKENS = toString cfg.maxOutputTokens;
        };
      };
    };
  };
}
