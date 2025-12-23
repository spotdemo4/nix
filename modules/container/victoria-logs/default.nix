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
      image = "docker.io/victoriametrics/victoria-logs:v1.43.0@sha256:bd0c9d57613902c8ad5c935e4fea94bad963ba19c4660c3646a0ca2791b0890e";
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
