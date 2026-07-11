{
  lib,
  config,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.victoria-traces;
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.victoria-traces = {
    enable = mkEnableOption "the VictoriaTraces container";
    image = containerOptions.mkImageOption "docker.io/victoriametrics/victoria-traces:v0.9.4@sha256:de1f0ce3916692236a711b58e48c65cc4138bfaa4e36324cfa25206e5485b187";

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
      containers.victoria-traces.containerConfig = {
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
        labels = toLabel {
          attrs.traefik = {
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
