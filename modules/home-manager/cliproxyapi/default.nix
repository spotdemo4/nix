{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.trev.services.cliproxyapi;
  yamlFormat = pkgs.formats.yaml { };
  generatedConfig = yamlFormat.generate "cliproxyapi.yaml" (
    lib.recursiveUpdate {
      host = "127.0.0.1";
      port = 8317;
      "auth-dir" = "${config.xdg.dataHome}/cliproxyapi";
      "api-keys" = [ cfg.apiKey ];
      debug = false;
      "request-log" = false;
      "logging-to-file" = false;
      "usage-statistics-enabled" = false;
      "remote-management" = {
        "allow-remote" = false;
        "secret-key" = "";
        "disable-control-panel" = true;
      };
    } cfg.settings
  );
  configPath =
    if cfg.configFile == null then
      "${config.xdg.configHome}/cliproxyapi/config.yaml"
    else
      toString cfg.configFile;
  cliProxyApiPackage = pkgs.writeShellApplication {
    name = "cli-proxy-api";
    text = ''
      exec ${lib.getExe cfg.package} --config ${lib.escapeShellArg configPath} "$@"
    '';
  };
  claudePackage = pkgs.writeShellApplication {
    name = "claude";
    text = ''
      export ANTHROPIC_BASE_URL=${lib.escapeShellArg cfg.claude.baseUrl}
      export ANTHROPIC_AUTH_TOKEN=${lib.escapeShellArg cfg.claude.authToken}
      export ANTHROPIC_CUSTOM_MODEL_OPTION=${lib.escapeShellArg cfg.claude.model}
      export ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg cfg.claude.haikuModel}
      export ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg cfg.claude.opusModel}
      export ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg cfg.claude.sonnetModel}
      export CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg cfg.claude.model}

      exec ${lib.getExe cfg.claude.package} \
        --model ${lib.escapeShellArg cfg.claude.model} \
        "$@"
    '';
  };
in
{
  options.trev.services.cliproxyapi = {
    enable = lib.mkEnableOption "CLIProxyAPI user service";

    package = lib.mkPackageOption pkgs.trev "cliproxyapi" { };

    apiKey = lib.mkOption {
      type = lib.types.str;
      default = "cliproxy-local";
      description = "Local client credential accepted by CLIProxyAPI.";
    };

    configFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      default = null;
      description = ''
        External CLIProxyAPI configuration file. When set, settings are ignored.
        Use this for configurations containing secrets that must not enter the Nix store.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        CLIProxyAPI settings merged with safe local-only defaults and rendered as YAML.
        Do not place secrets here because the generated configuration is stored in the Nix store.
      '';
    };

    claude = {
      enable = lib.mkEnableOption "Claude Code wrapper using CLIProxyAPI";

      package = lib.mkPackageOption pkgs "claude-code" { };

      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8317";
        description = "CLIProxyAPI endpoint used by Claude Code.";
      };

      authToken = lib.mkOption {
        type = lib.types.str;
        default = cfg.apiKey;
        defaultText = lib.literalExpression "config.trev.services.cliproxyapi.apiKey";
        description = "CLIProxyAPI client token used by Claude Code.";
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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cliProxyApiPackage ] ++ lib.optional cfg.claude.enable claudePackage;

    programs.claude-code = lib.mkIf cfg.claude.enable {
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

    xdg.configFile = lib.mkIf (cfg.configFile == null) {
      "cliproxyapi/config.yaml".source = generatedConfig;
    };

    systemd.user.services.cliproxyapi = {
      Unit = {
        Description = "CLIProxyAPI";
        Documentation = "https://help.router-for.me/";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };

      Service = {
        ExecStart = lib.getExe cliProxyApiPackage;
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
