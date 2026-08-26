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
    "port"
    "remote-management"
  ];
  overriddenSettings = builtins.filter (name: builtins.hasAttr name cfg.settings) reservedSettings;
  jsonFormat = pkgs.formats.json { };
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
      "remote-management" = {
        "allow-remote" = false;
        "secret-key" = "";
        "disable-control-panel" = true;
      };
    }
  );
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

      jq --rawfile api_key "$key_file" '
        ($api_key | sub("\\r?\\n$"; "")) as $key
        | if ($key == "" or ($key | test("[\\r\\n]"))) then
            error("CLIProxyAPI API key must be a non-empty single line")
          else
            .["api-keys"] = [$key]
          end
      ' ${lib.escapeShellArg configTemplate} > "$temporary"

      chmod 0600 "$temporary"
      mv -f "$temporary" "$output"
      trap - EXIT
    '';
  };
in
{
  options.trev.containers.cliproxyapi = {
    enable = mkEnableOption "CLIProxyAPI container";

    image = mkImageOption "docker.io/eceasy/cli-proxy-api:v7.2.143@sha256:c6fef08792488785b380fa776bcaf872e0c60a3f74fcb77effcfab74362ad70d";

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
    ];

    age.secrets.cliproxyapi.file = apiKeyFile;

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
    ];
  };
}
