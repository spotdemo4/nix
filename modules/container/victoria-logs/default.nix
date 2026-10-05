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
  cfg = config.trev.containers.victoria-logs;
in
{
  options.trev.containers.victoria-logs = {
    enable = mkEnableOption "the VictoriaLogs container";
    image = mkImageOption "docker.io/victoriametrics/victoria-logs:v1.53.0@sha256:251121fa882af99b95ba0c230a4a2f412ea602d2698c64a96c58dc9842bb755d";

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

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional arguments passed to VictoriaLogs.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.victoria-logs = {
      domains = [ cfg.domain ];
      port = 9428;
      auth = "trev";
    };

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
        exec = cfg.extraArgs;
      };

      networks.${cfg.networkName} = { };
      volumes.${cfg.volumeName} = { };
    };

    systemd.services.victoria-logs.serviceConfig.RestartSec = "5m";
  };
}
