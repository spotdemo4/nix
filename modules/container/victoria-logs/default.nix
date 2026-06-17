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
      image = "docker.io/victoriametrics/victoria-logs:v1.51.0@sha256:e16dd33a95623cc21730cf5285344ed9f97419eeaff7d24b039c135beb85ee7e";
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
