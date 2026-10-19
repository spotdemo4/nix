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

    image = mkImageOption "ghcr.io/linagora/tmail-web:v0.40.2@sha256:ba62c97d889990cb587c3a61ddd600e1d89bd5b7830c46c8c89d3dc2edd0283c";

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
