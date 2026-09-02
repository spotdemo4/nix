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
  reservedSettings = [
    "api-keys"
    "auth-dir"
    "host"
    "openai-compatibility"
    "port"
    "remote-management"
  ];
  overriddenSettings = builtins.filter (name: builtins.hasAttr name cfg.settings) reservedSettings;
  jsonFormat = pkgs.formats.json { };

  indexedProviders = lib.imap0 (
    index: provider: provider // { inherit index; }
  ) cfg.openaiCompatibility;

  toProviderConfig =
    provider:
    {
      name = provider.name;
      disabled = provider.disabled;
      base-url = provider.baseUrl;
      models = map (
        model:
        { inherit (model) name; } // lib.optionalAttrs (model.alias != null) { inherit (model) alias; }
      ) provider.models;
      # Internal marker consumed (and stripped) by generateConfig.
      key-index = provider.index;
    }
    // lib.optionalAttrs (provider.prefix != null) { inherit (provider) prefix; }
    // lib.optionalAttrs (provider.headers != { }) { headers = provider.headers; }
    // lib.optionalAttrs (provider.proxyUrl != null) { proxy-url = provider.proxyUrl; };

  providerKeySecret = provider: config.age.secrets."cliproxyapi-${provider.name}".path;

  configTemplate = jsonFormat.generate "cliproxyapi.json" (
    lib.recursiveUpdate {
      debug = false;
      "request-log" = false;
      "logging-to-file" = false;
      "usage-statistics-enabled" = false;
    } cfg.settings
    // {
      host = "0.0.0.0";
      port = cfg.port;
      "auth-dir" = "/root/.cli-proxy-api";
      "api-keys" = [ ];
      "openai-compatibility" = map toProviderConfig indexedProviders;
      "remote-management" = {
        "allow-remote" = false;
        "secret-key" = "";
        "disable-control-panel" = true;
      };
    }
  );

  rawfileArgs = lib.concatStringsSep "\n" (
    map (
      provider:
      "--rawfile provider_keys_${toString provider.index} ${lib.escapeShellArg (providerKeySecret provider)}"
    ) indexedProviders
  );

  keysObject =
    if indexedProviders == [ ] then
      "{ }"
    else
      "{ "
      + lib.concatStringsSep ", " (
        map (
          provider: ''"${toString provider.index}": $provider_keys_${toString provider.index}''
        ) indexedProviders
      )
      + " }";

  configProgram = ''
    ($api_key | sub("\\r?\\n$"; "")) as $key
    | if ($key == "" or ($key | test("[\\r\\n]"))) then
        error("CLIProxyAPI API key must be a non-empty single line")
      else . end
    | (
        ${keysObject}
        | to_entries
        | map(.value | sub("\\r?\\n$"; "") | split("\n") | map(select(length > 0)))
      ) as $all_keys
    | if any($all_keys[]; length == 0) then
        error("Provider API key file must contain at least one non-empty key")
      else . end
    | if any($all_keys[][]; test("\\r")) then
        error("Provider API keys must not contain carriage returns")
      else . end
    | .["openai-compatibility"] |= map(
        if has("key-index") then
          .["api-key-entries"] = ($all_keys[.["key-index"]] | map({ "api-key": . }))
          | del(.["key-index"])
        else . end
      )
    | .["api-keys"] = [$key]
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

    image = mkImageOption "docker.io/eceasy/cli-proxy-api:v7.2.147@sha256:f077e153476466e0ea8355400e39bf1508e637585b661ed3991b7b8129ce054d";

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

    settings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      description = "Non-secret CLIProxyAPI settings merged into the generated configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
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
    ];

    age.secrets = {
      cliproxyapi.file = apiKeyFile;
    }
    // builtins.listToAttrs (
      map (
        provider:
        lib.nameValuePair "cliproxyapi-${provider.name}" {
          file = toContentPath provider.apiKeyFile;
        }
      ) indexedProviders
    );

    virtualisation.quadlet = {
      containers.cliproxyapi = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          publishPorts = [ (toString cfg.port) ];
          volumes = [
            "/run/cliproxyapi/config.yaml:/CLIProxyAPI/config.yaml:ro"
            "${volumes.cliproxyapi.ref}:/root/.cli-proxy-api"
          ];
          labels = {
            traefik = {
              enable = true;
              http.routers.cliproxyapi = {
                rule = "Host(`${cfg.domain}`)";
                middlewares = "secure@file";
              };
            };
          };
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
    ++ map (provider: toContentPath provider.apiKeyFile) indexedProviders;
  };
}
