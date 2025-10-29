{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.stalwart.containerConfig = {
      image = "docker.io/stalwartlabs/stalwart:v0.14.1-alpine@sha256:1ff67f6d1fc41e689e09cc5c224bdd57711e9eb3be27b78a00c196354b9ec445";
      pull = "missing";
      volumes = [
        "${volumes.stalwart.ref}:/opt/stalwart"
        "/mnt/certs:/data/certs:ro"
      ];
      publishPorts = [
        "25:25" # smtp
        "443:443" # https
        "465:465" # smtps
        "993:993" # imaps
        "8080:8080" # http
      ];
      networks = [
        networks."stalwart".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            routers.stalwart = {
              rule = "HostRegexp(`stalwart.trev.(zip|kiwi|xyz)`)";
              service = "stalwart";
            };
            services.stalwart.loadbalancer.server = {
              port = 8080;
            };
          };
        };
      };
    };

    volumes = {
      stalwart = {};
    };

    networks = {
      stalwart = {};
    };
  };
}
