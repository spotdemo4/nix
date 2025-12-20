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
      image = "docker.io/victoriametrics/victoria-logs:v1.42.0@sha256:dff8243aa9a9b0f65ae850836088f11e6e44dd2a6138a7cfd99bc16e7c57460c";
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
