{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.programs.claude;
  claudePackage = pkgs.writeShellApplication {
    name = "claude";
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
      export ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg cfg.haikuModel}
      export ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg cfg.opusModel}
      export ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg cfg.sonnetModel}
      export CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg cfg.model}

      exec ${lib.getExe cfg.package} \
        --model ${lib.escapeShellArg cfg.model} \
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

    haikuModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.6-luna";
      description = "Model used when Claude Code selects Haiku.";
    };

    sonnetModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.6-terra";
      description = "Model used when Claude Code selects Sonnet.";
    };

    opusModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.6-sol";
      description = "Model used when Claude Code selects Opus.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.6-sol";
      description = "Model used by Claude Code and its subagents.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.cliproxyapi.file = self + /secrets/cliproxyapi.age;

    home.packages = [ claudePackage ];

    programs.claude-code = {
      enable = true;
      package = null;
      enableMcpIntegration = true;

      settings = {
        effortLevel = "high";
        enableWorkflows = true;
        workflowSizeGuideline = "medium";
      };

      context = ''
        # Workflow orchestration

        Default to the Workflow tool for substantive tasks whenever the work can be usefully decomposed into independent workstreams, parallel research, competing approaches, specialist reviews, or an implementation-and-verification pipeline. Work directly only when the task is trivial, inherently sequential, or too small for workflow coordination to improve the result.

        When composing a workflow:

        - Use multiple subagents with deliberately different perspectives and model assignments. Avoid a single-model monoculture.
        - Use `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna` across the workflow. For three or more meaningful independent workstreams, include all three models when practical; for smaller workflows, use at least two models when a second opinion would improve the result.
        - Set `effort: "high"` explicitly on every workflow subagent.
        - Use `gpt-5.6-sol` for the hardest architecture, synthesis, and adversarial verification; `gpt-5.6-terra` for balanced implementation, analysis, and review; and `gpt-5.6-luna` for focused reconnaissance, bounded checks, and additional independent opinions.
        - Give each subagent a precise, non-overlapping remit. Run independent work concurrently with `pipeline()` or `parallel()` as appropriate, then reconcile disagreements and synthesize the strongest result.
        - Prefer explicit per-agent model and effort assignments over relying on the global subagent fallback.
      '';
    };
  };
}
