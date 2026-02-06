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
    containers.victoria-logs.containerConfig = {
      image = "docker.io/victoriametrics/victoria-logs:v1.45.0@sha256:01bfa0f80d8d6134753b0be0f206c3458f74a14e81bb570f8c3d2f20af2a24a0";
      pull = "missing";
      volumes = [
        "${volumes."victoria-logs".ref}:/victoria-logs-data"
      ];
      publishPorts = [
        "9428:9428"
      ];
      networks = [
        networks."victoria-logs".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            routers.victoria-logs = {
              rule = "Host(`logs.trev.xyz`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };
    };

    networks = {
      victoria-logs = { };
    };

    volumes = {
      victoria-logs = { };
    };
  };
}
