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
  cfg = config.trev.containers.victoria-logs;
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  options.trev.containers.victoria-logs = {
    enable = mkEnableOption "the VictoriaLogs container";
    image = mkImageOption "docker.io/victoriametrics/victoria-logs:v1.52.0@sha256:47b820890d64c4575a2a0a46415dcd8a4fd59a0f1fcd6a377693d7aea639442e";

    domain = mkOption {
      type = types.str;
      default = "logs.trev.xyz";
      description = "Domain routed to VictoriaLogs.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "9428:9428" ];
      description = "Ports to publish from VictoriaLogs.";
    };

    networkName = mkOption {
      type = types.str;
      default = "victoria-logs";
      description = "Name of the VictoriaLogs Quadlet network.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "victoria-logs";
      description = "Name of the persistent VictoriaLogs data volume.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.victoria-logs.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/victoria-logs-data"
        ];
        publishPorts = cfg.publishPorts;
        networks = [
          networks.${cfg.networkName}.ref
        ];
        labels = {
          traefik = {
            enable = true;
            http = {
              routers.victoria-logs = {
                rule = "Host(`${cfg.domain}`)";
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
