{
  config,
  lib,
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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.tmail;
  stalwart = lib.attrByPath [ "trev" "containers" "stalwart" ] { enable = false; } config;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  stalwartNetwork = lib.attrByPath [ "stalwart" ] { ref = "stalwart"; } networks;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.tmail = {
    enable = mkEnableOption "TMail web client container";

    image = containerOptions.mkImageOption "ghcr.io/linagora/tmail-web:v0.30.1@sha256:4b69b883f59f35061ba25d4f5a72d3340e3ac2a16af5e1b900e03ab63ce86f6f";

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

    virtualisation.quadlet.containers.tmail.containerConfig = {
      image = cfg.image;
      pull = "missing";
      environments.SERVER_URL = cfg.serverUrl;
      publishPorts = [ "80" ];
      networks = [
        stalwartNetwork.ref
      ];
      labels = toLabel {
        attrs.traefik = {
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
