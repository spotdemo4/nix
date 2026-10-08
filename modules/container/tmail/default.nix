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

    image = mkImageOption "ghcr.io/linagora/tmail-web:v0.39.3@sha256:49dc7308232bc582349ac50439ec61408fe1ba121bdc5bd265ff762f94d59a45";

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

    port = mkOption {
      type = types.port;
      default = 8096;
      description = "TMail port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.tmail = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
      auth = "admin";
    };

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
      publishPorts = [ "${toString cfg.port}:80" ];
      networks = [
        stalwartNetwork.ref
      ];
    };
  };
}
