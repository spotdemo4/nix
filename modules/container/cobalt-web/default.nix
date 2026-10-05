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
  cfg = config.trev.containers.cobalt-web;
  cobalt = lib.attrByPath [ "trev" "containers" "cobalt" ] { enable = false; } config;
in
{
  options.trev.containers.cobalt-web = {
    enable = mkEnableOption "Cobalt web container";

    image = mkImageOption "ghcr.io/spotdemo4/cobalt-web:11.7@sha256:30392487965b2c96f70f04ec5e3ef24a7804eec6ef0c7b9fd7d1e19ed955d1c9";

    defaultApiUrl = mkOption {
      type = types.str;
      default = "https://cobalt-api.trev.zip/";
      description = "Default Cobalt API URL used by the web client.";
    };

    webHost = mkOption {
      type = types.str;
      default = "trev.zip";
      description = "Host value advertised by the Cobalt web client.";
    };

    domain = mkOption {
      type = types.str;
      default = "cobalt.trev.zip";
      description = "Domain routed to the Cobalt web client.";
    };

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Cobalt web port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.cobalt-web = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      # static-web-server accepts h2c alongside HTTP/1.1.
      upstreamProtocol = "h2c";
    };

    assertions = [
      {
        assertion = cobalt.enable;
        message = "trev.containers.cobalt-web requires trev.containers.cobalt.enable = true";
      }
    ];

    virtualisation.quadlet.containers.cobalt-web.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      environments = {
        WEB_DEFAULT_API = cfg.defaultApiUrl;
        WEB_HOST = cfg.webHost;
      };
      publishPorts = [ "${toString cfg.port}:8787" ];
    };
  };
}
