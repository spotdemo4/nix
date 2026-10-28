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
  inherit (config.virtualisation.quadlet)
    networks
    volumes
    ;
  cfg = config.trev.containers.stalwart;
in
{
  options.trev.containers.stalwart = {
    enable = mkEnableOption "Stalwart mail server container";

    image = mkImageOption "docker.io/stalwartlabs/stalwart:v1.0.1-alpine@sha256:fae158ca8320581963058f960d790ca767af653d5a4187d3934bba86c90d5329";

    certificatesPath = mkOption {
      type = types.str;
      default = "/mnt/certs";
      description = "Host path containing Stalwart certificates.";
    };

    domain = mkOption {
      type = types.str;
      default = "stalwart.trev.xyz";
      description = "Domain routed to the Stalwart web interface.";
    };
  };

  config = mkIf cfg.enable {
    # Requires the gateway in Stalwart's proxy.trusted-networks for its http
    # listener, or Stalwart reads the PROXY header as garbage.
    trev.proxy.routes.stalwart = {
      domains = [ cfg.domain ];
      port = 8080;
      proxyProtocol = true;
    };

    virtualisation.quadlet = {
      containers.stalwart.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        # The 1.0 store was migrated from 0.16 with stalwart-migrate into new
        # volumes; its config.json names /var/lib/stalwart-v1.
        volumes = [
          "${volumes.stalwart-v1-conf.ref}:/etc/stalwart"
          "${volumes.stalwart-v1-data.ref}:/var/lib/stalwart-v1"
          "${cfg.certificatesPath}:/data/certs:ro"
        ];
        publishPorts = [
          "25:25" # smtp
          "443:443" # https
          "465:465" # smtps
          "993:993" # imaps
          "8080:8080" # http
        ];
        networks = [
          networks.stalwart.ref
        ];
      };

      volumes = {
        # 0.16 store, kept for rollback.
        stalwart-conf = { };
        stalwart-data = { };
        stalwart-v1-conf = { };
        stalwart-v1-data = { };
      };

      networks.stalwart = { };
    };
  };
}
