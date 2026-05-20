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
      image = "docker.io/victoriametrics/victoria-traces:v0.9.0@sha256:2b1c56015457912a8d2d6bd02c1cf90e08f63f35296ab40a06687b97fff8a8cb";
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
