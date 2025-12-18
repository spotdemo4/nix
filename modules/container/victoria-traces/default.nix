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
    containers.victoria-traces.containerConfig = {
      image = "docker.io/victoriametrics/victoria-traces:v0.5.1@sha256:42730c41a0eb9af8ba42098fb27574af5f00cb275dd4a40bc08619d125fcb62d";
      pull = "missing";
      volumes = [
        "${volumes."victoria-traces".ref}:/victoria-traces-data"
      ];
      publishPorts = [
        "10428:10428"
      ];
      networks = [
        networks."victoria-traces".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.victoria-traces = {
            rule = "Host(`victoria-traces.trev.xyz`)";
            middlewares = "secure-trev@file";
          };
        };
      };
    };

    networks = {
      victoria-traces = { };
    };

    volumes = {
      victoria-traces = { };
    };
  };
}
