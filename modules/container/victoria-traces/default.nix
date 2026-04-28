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
      image = "docker.io/victoriametrics/victoria-traces:v0.8.2@sha256:0acb761e60ce86e7b83e5e9f8648421004ea922c5bf1e0755d0346536d747eea";
      pull = "missing";
      volumes = [
        "${volumes."victoria-traces".ref}:/victoria-traces-data"
      ];
      publishPorts = [
        "10428:10428" # http
        "4317:4317" # grpc
      ];
      networks = [
        networks."victoria-traces".ref
      ];
      exec = [
        "-otlpGRPCListenAddr=:4317"
        "-otlpGRPC.tls=false"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            services.victoria-traces.loadbalancer.server.port = 10428;
            routers.victoria-traces = {
              rule = "Host(`traces.trev.xyz`)";
              service = "victoria-traces";
              middlewares = "secure-trev@file";
            };
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
