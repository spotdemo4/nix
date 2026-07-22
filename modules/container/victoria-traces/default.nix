{
  self,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    ;
  inherit (config.virtualisation.quadlet)
    networks
    volumes
    ;
  cfg = config.trev.containers.victoria-traces;
in
{
  options.trev.containers.victoria-traces = {
    enable = mkEnableOption "the VictoriaTraces container";
    image = mkImageOption "docker.io/victoriametrics/victoria-traces:v0.10.0@sha256:66e784a595c4a88e5b1dfab5d153dea442cf1caaeae4d67839c550414c33b3b0";

    domain = mkOption {
      type = types.str;
      default = "traces.trev.xyz";
      description = "Domain routed to VictoriaTraces.";
    };

    servicePort = mkOption {
      type = types.port;
      default = 10428;
      description = "Internal VictoriaTraces HTTP port routed by Traefik.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [
        "10428:10428"
        "4317:4317"
      ];
      description = "Ports to publish from VictoriaTraces.";
    };

    networkName = mkOption {
      type = types.str;
      default = "victoria-traces";
      description = "Name of the VictoriaTraces Quadlet network.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "victoria-traces";
      description = "Name of the persistent VictoriaTraces data volume.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.victoria-traces.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/victoria-traces-data"
        ];
        publishPorts = cfg.publishPorts;
        networks = [
          networks.${cfg.networkName}.ref
        ];
        exec = [
          "-otlpGRPCListenAddr=:4317"
          "-otlpGRPC.tls=false"
        ];
        labels = {
          traefik = {
            enable = true;
            http = {
              services.victoria-traces.loadbalancer.server.port = cfg.servicePort;
              routers.victoria-traces = {
                rule = "Host(`${cfg.domain}`)";
                service = "victoria-traces";
                middlewares = "secure-trev@file";
              };
            };
          };
        };
      };

      networks.${cfg.networkName} = { };
      volumes.${cfg.volumeName} = { };
    };
  };
}
