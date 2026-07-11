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
  cfg = config.trev.containers.satisfactory;
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.satisfactory = {
    enable = mkEnableOption "the Satisfactory container";
    image = containerOptions.mkImageOption "ghcr.io/wolveix/satisfactory-server:v1.9.10@sha256:e0f2f8c9759875c97add050d3a344167b71cb41bef68e85771f1ea8cc8c00301";

    environments = mkOption {
      type = types.attrsOf types.str;
      default = {
        MAXPLAYERS = "4";
        PGID = "1000";
        PUID = "1000";
        STEAMBETA = "false";
      };
      description = "Environment variables passed to the Satisfactory server.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [
        "7777:7777/tcp" # satisfactory-server
        "7777:7777/udp" # satisfactory-query
        "8888:8888/tcp" # satisfactory-game
      ];
      description = "Ports to publish from Satisfactory.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "satisfactory";
      description = "Name of the persistent Satisfactory configuration volume.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.satisfactory.containerConfig = {
        image = cfg.image;
        pull = "missing";
        environments = cfg.environments;
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/config"
        ];
        publishPorts = cfg.publishPorts;
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            tcp = {
              services = {
                satisfactory-server.loadbalancer.server.port = 7777;
                satisfactory-game.loadbalancer.server.port = 8888;
              };
              routers = {
                satisfactory-server = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "satisfactory-server";
                  service = "satisfactory-server";
                };
                satisfactory-game = {
                  rule = "HostSNI(`*`)";
                  entryPoints = "satisfactory-game";
                  service = "satisfactory-game";
                };
              };
            };
            udp = {
              services.satisfactory-query.loadbalancer.server.port = 7777;
              routers.satisfactory-query = {
                entryPoints = "satisfactory-query";
                service = "satisfactory-query";
              };
            };
          };
        };
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
