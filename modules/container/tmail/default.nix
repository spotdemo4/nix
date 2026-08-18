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

    image = mkImageOption "ghcr.io/linagora/tmail-web:v0.35.0@sha256:d750474ffdf9f7ce5d4228028d872556b07fb417d7130709b64ab558c93283ff";

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
