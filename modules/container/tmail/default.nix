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
    ;
  cfg = config.trev.containers.tmail;
  stalwart = lib.attrByPath [ "trev" "containers" "stalwart" ] { enable = false; } config;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  stalwartNetwork = lib.attrByPath [ "stalwart" ] { ref = "stalwart"; } networks;
in
{
  options.trev.containers.tmail = {
    enable = mkEnableOption "TMail web client container";

    image = mkImageOption "ghcr.io/linagora/tmail-web:v0.33.0@sha256:2ccbece1fb9d407b79c93113f14d34c9ac1afa716a29e0352331fb47c63625d8";

    serverUrl = mkOption {
      type = types.str;
      default = "https://mail.trev.xyz";
      description = "Mail server URL used by TMail.";
    };

    domain = mkOption {
      type = types.str;
      default = "tmail.trev.xyz";
      description = "Domain routed to TMail.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = stalwart.enable;
        message = "trev.containers.tmail requires trev.containers.stalwart.enable = true";
      }
    ];

    virtualisation.quadlet.containers.tmail.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      environments.SERVER_URL = cfg.serverUrl;
      publishPorts = [ "80" ];
      networks = [
        stalwartNetwork.ref
      ];
      labels = {
        traefik = {
          enable = true;
          http.routers.tmail = {
            rule = "Host(`${cfg.domain}`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };
  };
}
