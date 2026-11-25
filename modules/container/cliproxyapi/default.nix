{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    toContentPath
    ;
  inherit (config.virtualisation.quadlet) volumes;
  cfg = config.trev.containers.cliproxyapi;
  apiKeyFile = toContentPath cfg.apiKeyFile;
  jsonFormat = pkgs.formats.json { };

  # The configuration uses the v8 layout, where the root api-keys holds upstream
  # credentials and client keys live under access.api-keys. Legacy root fields
  # are rejected so they cannot silently shadow, or be shadowed by, v8 fields.
  settingsRoots = [
    "client"
    "credentials"
    "models"
    "multimedia"
    "oauth"
    "observability"
    "plugins"
    "requests"
    "routing"
    "server"
    "upstream"
  ];
  reservedSettings = [
    [
      "oauth"
      "auth-dir"
    ]
    [
      "routing"
      "force-model-prefix"
    ]
    [
      "server"
      "host"
    ]
    [
      "server"
      "port"
    ]
  ];
  unknownSettings = lib.subtractLists settingsRoots (lib.attrNames cfg.settings);
  overriddenSettings = map (lib.concatStringsSep ".") (
    builtins.filter (path: lib.hasAttrByPath path cfg.settings) reservedSettings
  );

  # Every API key file becomes one entry in the generated configuration's
  # secret list; key-index points a credential group at its entry.
  keyedProviders = lib.imap0 (
    index: provider:
    provider
    // {
      inherit index;
      secretName = "cliproxyapi-${provider.name}";
    }
  ) cfg.openaiCompatibility;
  keyedClaudeKeys = lib.imap0 (
    index: key:
    key
    // {
      index = lib.length keyedProviders + index;
      secretName = "cliproxyapi-claude-${key.name}";
    }
  ) cfg.claudeApiKeys;
  keyedEntries = keyedProviders ++ keyedClaudeKeys;

  toProviderConfig =
    provider:
    {
      name = provider.name;
      priority = provider.priority;
      disabled = provider.disabled;
      base-url = provider.baseUrl;
      models = map (
        model:
        { inherit (model) name; } // lib.optionalAttrs (model.alias != null) { inherit (model) alias; }
      ) provider.models;
      # Internal markers consumed (and stripped) by generateConfig.
      key-index = provider.index;
      # CLIProxyAPI reads proxy-url on each key, not on the provider.
      key-template = lib.optionalAttrs (provider.proxyUrl != null) { proxy-url = provider.proxyUrl; };
    }
    // lib.optionalAttrs (provider.prefix != null) { inherit (provider) prefix; }
    // lib.optionalAttrs (provider.headers != { }) { headers = provider.headers; };

  toClaudeConfig =
    key:
    {
      name = key.name;
      priority = key.priority;
      key-index = key.index;
      # Forward requests as the client sent them instead of disguising them as
      # Claude Code, and strip any Claude Code identity a client attaches.
      key-template.cloak.mode = "never";
    }
    // lib.optionalAttrs (key.prefix != null) { inherit (key) prefix; };

  configTemplate = jsonFormat.generate "cliproxyapi.json" (
    lib.foldl' lib.recursiveUpdate { } [
      {
        observability = {
          logs = {
            debug = false;
            request-log = false;
            logging-to-file = false;
          };
          usage.usage-statistics-enabled = false;
        };
      }
      cfg.settings
      {
        config-version = 8;
        server = {
          host = "0.0.0.0";
          port = cfg.port;
        };
        oauth.auth-dir = "/root/.cli-proxy-api";
        access.api-keys = [ ];
        management = {
          allow-remote = false;
          secret-key = "";
          disable-control-panel = true;
        };
        # Without this, a prefixed credential also serves unprefixed model names,
        # so a prefix would only add a route instead of restricting one.
        routing.force-model-prefix = true;
        api-keys = {
          openai-compatibility = map toProviderConfig keyedProviders;
          claude = map toClaudeConfig keyedClaudeKeys;
        };
      }
    ]
  );

  rawfileArgs = lib.concatStringsSep " " (
    map (
      entry:
      "--rawfile secret_${toString entry.index} ${
        lib.escapeShellArg config.age.secrets.${entry.secretName}.path
      }"
    ) keyedEntries
  );

  secretsArray = "[${
    lib.concatStringsSep ", " (map (entry: "$secret_${toString entry.index}") keyedEntries)
  }]";

  configProgram = ''
    ($api_key | sub("\\r?\\n$"; "")) as $key
    | if ($key == "" or ($key | test("[\\r\\n]"))) then
        error("CLIProxyAPI API key must be a non-empty single line")
      else . end
    | (
        ${secretsArray}
        | map(sub("\\r?\\n$"; "") | split("\n") | map(select(length > 0)))
      ) as $all_keys
    | if any($all_keys[]; length == 0) then
        error("Upstream API key file must contain at least one non-empty key")
      else . end
    | if any($all_keys[][]; test("\\r")) then
        error("Upstream API keys must not contain carriage returns")
      else . end
    | .["api-keys"] |= map_values(map(
        if has("key-index") then
          . as $group
          | .keys = ($all_keys[$group["key-index"]] | map($group["key-template"] + { "api-key": . }))
          | del(.["key-index"], .["key-template"])
        else . end
      ))
    | .access["api-keys"] = [$key]
  '';

  generateConfig = pkgs.writeShellApplication {
    name = "generate-cliproxyapi-config";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      key_file=${lib.escapeShellArg config.age.secrets.cliproxyapi.path}
      output=/run/cliproxyapi/config.yaml
      temporary="$(mktemp "''${output}.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT

      jq --rawfile api_key "$key_file" \
        ${rawfileArgs} \
        '${configProgram}' \
        ${lib.escapeShellArg configTemplate} > "$temporary"

      chmod 0600 "$temporary"
      mv -f "$temporary" "$output"
      trap - EXIT
    '';
  };
in
{
  options.trev.containers.cliproxyapi = {
    enable = mkEnableOption "CLIProxyAPI container";

    image = mkImageOption "docker.io/eceasy/cli-proxy-api:v8.1.4@sha256:32fb7dfc272bf63daee4dcaaa679095aad431ceed31416f98ea55f3d1d7db77a";

    domain = mkOption {
      type = types.str;
      default = "proxy.trev.xyz";
      description = "Domain routed to CLIProxyAPI.";
    };

    port = mkOption {
      type = types.port;
      default = 8317;
      description = "CLIProxyAPI listen port.";
    };

    apiKeyFile = mkOption {
      type = types.path;
      default = self + /secrets/cliproxyapi.age;
      description = "Agenix-encrypted CLIProxyAPI client API key.";
    };

    openaiCompatibility = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Provider name used by CLIProxyAPI.";
            };
            priority = mkOption {
              type = types.int;
              default = 0;
              description = ''
                Selection priority when multiple providers or credentials match.
                Higher values are preferred; negative values allow fallback
                behind OAuth credentials with the default priority of zero.
              '';
            };
            disabled = mkOption {
              type = types.bool;
              default = false;
              description = "Disable this provider without removing it.";
            };
            prefix = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Require calls like `<prefix>/<model>` to target this provider.";
            };
            baseUrl = mkOption {
              type = types.str;
              description = "Base URL of the provider API.";
            };
            headers = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Extra HTTP headers sent to the provider.";
            };
            proxyUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Optional proxy applied to every API key of this provider.";
            };
            apiKeyFile = mkOption {
              type = types.path;
              description = "Agenix-encrypted file containing one API key per line.";
            };
            models = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    name = mkOption {
                      type = types.str;
                      description = "The actual model name at the provider.";
                    };
                    alias = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "The alias used in the API.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Models exposed by this provider.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        OpenAI-compatible providers. API keys are injected from agenix
        secrets into the generated configuration at container start.
      '';
    };

    claudeApiKeys = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.strMatching "[A-Za-z0-9_-]+";
              description = "Credential group name, also used to name its agenix secret.";
            };
            priority = mkOption {
              type = types.int;
              default = 0;
              description = ''
                Selection priority when multiple credentials match. Higher
                values are preferred; a negative value keeps these keys as a
                fallback for when Claude OAuth credentials, with the default
                priority of zero, are rate limited or out of usage.
              '';
            };
            prefix = mkOption {
              type = types.nullOr (types.strMatching "[A-Za-z0-9_-]+");
              default = null;
              description = ''
                Model prefix clients must use to reach these keys, as in
                `<prefix>/claude-sonnet-5-5`. When set, unprefixed requests
                never use them.
              '';
            };
            apiKeyFile = mkOption {
              type = types.path;
              description = "Agenix-encrypted file containing one Claude API key per line.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Claude Platform API keys, served at api.anthropic.com with every Claude
        model. Requests are forwarded as the client sent them, without Claude
        Code cloaking. API keys are injected from agenix secrets into the
        generated configuration at container start.
      '';
    };

    settings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        Non-secret CLIProxyAPI settings, in the v8 layout, merged into the
        generated configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.cliproxyapi = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    assertions = [
      {
        assertion = unknownSettings == [ ];
        message = "trev.containers.cliproxyapi.settings only accepts the v8 sections ${lib.concatStringsSep ", " settingsRoots}; found: ${lib.concatStringsSep ", " unknownSettings}";
      }
      {
        assertion = overriddenSettings == [ ];
        message = "trev.containers.cliproxyapi.settings cannot override: ${lib.concatStringsSep ", " overriddenSettings}";
      }
      {
        assertion =
          lib.length cfg.openaiCompatibility
          == lib.length (lib.unique (map (p: p.name) cfg.openaiCompatibility));
        message = "trev.containers.cliproxyapi.openaiCompatibility provider names must be unique";
      }
      {
        assertion =
          lib.length keyedEntries == lib.length (lib.unique (map (entry: entry.secretName) keyedEntries));
        message = "trev.containers.cliproxyapi: openaiCompatibility and claudeApiKeys names must map to unique secrets";
      }
    ];

    age.secrets = {
      cliproxyapi.file = apiKeyFile;
    }
    // builtins.listToAttrs (
      map (
        entry: lib.nameValuePair entry.secretName { file = toContentPath entry.apiKeyFile; }
      ) keyedEntries
    );

    virtualisation.quadlet = {
      containers.cliproxyapi = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          publishPorts = [ "${toString cfg.port}:${toString cfg.port}" ];
          volumes = [
            "/run/cliproxyapi/config.yaml:/CLIProxyAPI/config.yaml:ro"
            "${volumes.cliproxyapi.ref}:/root/.cli-proxy-api"
          ];
        };

        serviceConfig = {
          ExecStartPre = lib.getExe generateConfig;
          Restart = "on-failure";
          RestartSec = 5;
          RuntimeDirectory = "cliproxyapi";
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
        };
      };

      volumes.cliproxyapi = { };
    };

    systemd.services.cliproxyapi.restartTriggers = [
      apiKeyFile
      configTemplate
    ]
    ++ map (entry: toContentPath entry.apiKeyFile) keyedEntries;
  };
}
