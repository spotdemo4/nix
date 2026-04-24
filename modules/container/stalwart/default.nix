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
      image = "docker.io/stalwartlabs/stalwart:v0.16.0-alpine@sha256:1e6acf43a3cf56eb9121e60fdbc95da81c86b1488357c88fa2b74f7e8b461d0f";
      pull = "missing";
      volumes = [
        "${volumes.stalwart.ref}:/opt/stalwart"
        "${volumes.stalwart-conf.ref}:/etc/stalwart"
        "${volumes.stalwart-data.ref}:/var/lib/stalwart"
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
      stalwart-conf = { };
      stalwart-data = { };
    };

    networks = {
      stalwart = { };
    };
  };
}
