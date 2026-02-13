{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.stalwart.containerConfig = {
      image = "docker.io/stalwartlabs/stalwart:v0.15.4-alpine@sha256:a99c020d6059584101908e027e7505eef87758eb9b21f7c7c1211f0b43c1276e";
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
              rule = "Host(`stalwart.trev.xyz`)";
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
      stalwart = { };
    };

    networks = {
      stalwart = { };
    };
  };
}
