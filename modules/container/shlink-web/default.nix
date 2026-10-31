{
  self,
  config,
  lib,
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
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    containers
    ;
  cfg = config.trev.containers.shlink-web;
  shlink = lib.attrByPath [ "trev" "containers" "shlink" ] { enable = false; } config;
  shlinkContainer = lib.attrByPath [ "shlink" ] { ref = "shlink"; } containers;
in
{
  options.trev.containers.shlink-web = {
    enable = mkEnableOption "Shlink web client container";

    image = mkImageOption "docker.io/shlinkio/shlink-web-client:4.9.0@sha256:9ea53f612d361de240555036065e2b8ea0cd0411b0125afaf2f7d39f2a928f18";

    serverUrl = mkOption {
      type = types.str;
      default = "https://trev.rs";
      description = "Public Shlink server URL.";
    };

    domain = mkOption {
      type = types.str;
      default = "s.trev.rs";
      description = "Domain routed to the Shlink web client.";
    };

    port = mkOption {
      type = types.port;
      default = 8083;
      description = "Shlink web client port published on the host.";
    };

    apiSecret = mkOption {
      type = secretType;
      default.ref = "shlink";
      description = "Shlink API key secret registered by the Shlink container.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.shlink-web = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      auth = "admin";
    };

    assertions = [
      {
        assertion = shlink.enable;
        message = "trev.containers.shlink-web requires trev.containers.shlink.enable = true";
      }
    ];

    virtualisation.quadlet.containers.shlink-web = {
      containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        secrets = [
          {
            inherit (cfg.apiSecret) ref;
            type = "env";
            target = "SHLINK_SERVER_API_KEY";
          }
        ];
        environments.SHLINK_SERVER_URL = cfg.serverUrl;
        publishPorts = [ "${toString cfg.port}:8080" ];
      };

      unitConfig = {
        After = shlinkContainer.ref;
        BindsTo = shlinkContainer.ref;
      };
    };
  };
}
