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
      image = "docker.io/victoriametrics/victoria-logs:v1.46.0@sha256:022d57bc5cf206131d4540297818afb134bca4236fb0e71e596d67e5dce6acc3";
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
