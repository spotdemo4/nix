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
    secretReferenceType
    ;
  cfg = config.trev.containers.shlink-web;
  shlink = lib.attrByPath [ "trev" "containers" "shlink" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) containers;
  shlinkContainer = lib.attrByPath [ "shlink" ] { ref = "shlink"; } containers;
in
{
  options.trev.containers.shlink-web = {
    enable = mkEnableOption "Shlink web client container";

    image = mkImageOption "docker.io/shlinkio/shlink-web-client:4.8.0@sha256:ec804a7f9dc8d5f64615c780106d4d954ec81648dc2a1393442c68da8e48e102";

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

    redirectDomain = mkOption {
      type = types.str;
      default = "trev.rs";
      description = "Shlink domain whose root redirects to the web client.";
    };

    apiSecret = mkOption {
      type = secretReferenceType;
      default.ref = "shlink";
      description = "Shlink API key secret registered by the Shlink container.";
    };
  };

  config = mkIf cfg.enable {
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
          "${cfg.apiSecret.env},target=SHLINK_SERVER_API_KEY"
        ];
        environments.SHLINK_SERVER_URL = cfg.serverUrl;
        publishPorts = [ "8080" ];
        labels = {
          traefik = {
            enable = true;
            http = {
              middlewares.shlink-web-redirect.redirectRegex = {
                regex = "^https://${lib.escapeRegex cfg.redirectDomain}/";
                replacement = "https://${cfg.domain}/";
              };
              routers = {
                shlink-web = {
                  rule = "Host(`${cfg.domain}`)";
                  middlewares = "secure-admin@file";
                };
                shlink-web-redirect = {
                  rule = "Host(`${cfg.redirectDomain}`) && Path(`/`) && Method(`GET`)";
                  middlewares = "shlink-web-redirect@redis";
                  service = "noop@internal";
                };
              };
            };
          };
        };
      };

      unitConfig = {
        After = shlinkContainer.ref;
        BindsTo = shlinkContainer.ref;
      };
    };
  };
}
