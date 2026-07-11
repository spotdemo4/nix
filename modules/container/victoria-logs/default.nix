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
  cfg = config.trev.containers.victoria-logs;
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.victoria-logs = {
    enable = mkEnableOption "the VictoriaLogs container";
    image = containerOptions.mkImageOption "docker.io/victoriametrics/victoria-logs:v1.51.0@sha256:e16dd33a95623cc21730cf5285344ed9f97419eeaff7d24b039c135beb85ee7e";

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
      containers.victoria-logs.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/victoria-logs-data"
        ];
        publishPorts = cfg.publishPorts;
        networks = [
          networks.${cfg.networkName}.ref
        ];
        labels = toLabel {
          attrs.traefik = {
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
