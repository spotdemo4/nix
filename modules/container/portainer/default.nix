{
  self,
  config,
  lib,
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
  cfg = config.trev.containers.portainer;
in
{
  options.trev.containers.portainer = {
    enable = mkEnableOption "the Portainer container";

    image = mkImageOption "docker.io/portainer/portainer-ce:2.45.1@sha256:4d616db18cfeb5dd41a69c0958bc825c84483ea9cde1106eb82a5d26f3bd8b0e";

    podmanSocket = mkOption {
      type = types.str;
      default = "/run/podman/podman.sock";
      description = "Host Podman socket exposed to Portainer.";
    };

    routerRule = mkOption {
      type = types.str;
      default = "HostRegexp(`portainer.trev.(zip|kiwi)`)";
      description = "Traefik routing rule for Portainer.";
    };

    servicePort = mkOption {
      type = types.port;
      default = 9000;
      description = "Internal Portainer HTTP port routed by Traefik.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "portainer";
      description = "Quadlet volume containing Portainer data.";
    };

    networkName = mkOption {
      type = types.str;
      default = "traefik";
      description = "Quadlet network shared with Traefik.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.portainer = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          volumes = [
            "${cfg.podmanSocket}:/var/run/docker.sock"
            "${volumes.${cfg.volumeName}.ref}:/data"
          ];
          networks = [
            networks.${cfg.networkName}.ref
          ];
          labels = {
            traefik = {
              enable = true;
              http = {
                routers.portainer = {
                  rule = cfg.routerRule;
                  middlewares = "secure-trev@file";
                };
                services.portainer.loadbalancer.server = {
                  scheme = "http";
                  port = cfg.servicePort;
                };
              };
            };
          };
        };

        unitConfig = {
          After = "podman.socket";
          BindsTo = "podman.socket";
          ReloadPropagatedFrom = "podman.socket";
        };
      };

      volumes.${cfg.volumeName} = { };
      networks.${cfg.networkName} = { };
    };
  };
}
