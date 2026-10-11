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

    image = mkImageOption "docker.io/stalwartlabs/stalwart:v0.16.26-alpine@sha256:3f6cfcd6ddae9a4ba1e2057e334bb2395c2c7ecceecfffc2bf639717b55b1478";

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
        volumes = [
          "${volumes.stalwart-conf.ref}:/etc/stalwart"
          "${volumes.stalwart-data.ref}:/var/lib/stalwart"
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
        stalwart-conf = { };
        stalwart-data = { };
      };

      networks.stalwart = { };
    };
  };
}
