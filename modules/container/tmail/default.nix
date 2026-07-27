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

    image = mkImageOption "ghcr.io/linagora/tmail-web:v0.32.1@sha256:3782da1787f777717cd71b492b3e241663992e23bc2cb27428fffee319baebfd";

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
