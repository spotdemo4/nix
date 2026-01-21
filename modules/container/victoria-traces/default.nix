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
      image = "docker.io/victoriametrics/victoria-traces:v0.7.0@sha256:992b03c8eff7d30cb6b35506be162c8c93306d4965fda4cd88d635e9fe7eb7d5";
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
