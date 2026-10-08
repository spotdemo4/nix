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
    volumes
    ;
  cfg = config.trev.containers.portainer;
in
{
  options.trev.containers.portainer = {
    enable = mkEnableOption "the Portainer container";

    image = mkImageOption "docker.io/portainer/portainer-ce:2.45.2@sha256:03f94a406496dc84d37b552795fc424ccad8d0d7200353b6a82915f6e8f73ab0";

    podmanSocket = mkOption {
      type = types.str;
      default = "/run/podman/podman.sock";
      description = "Host Podman socket exposed to Portainer.";
    };

    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "portainer.trev.zip"
        "portainer.trev.kiwi"
      ];
      description = "Domains routed to Portainer.";
    };

    servicePort = mkOption {
      type = types.port;
      default = 9000;
      description = "Portainer port published on the host loopback.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "portainer";
      description = "Quadlet volume containing Portainer data.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.portainer = {
      inherit (cfg) domains;
      # trev-proxy runs on the host network next to Portainer.
      address = "127.0.0.1";
      port = cfg.servicePort;
      auth = "trev";
    };

    virtualisation.quadlet = {
      containers.portainer = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          volumes = [
            "${cfg.podmanSocket}:/var/run/docker.sock"
            "${volumes.${cfg.volumeName}.ref}:/data"
          ];
          publishPorts = [ "127.0.0.1:${toString cfg.servicePort}:9000" ];
        };

        unitConfig = {
          After = "podman.socket";
          BindsTo = "podman.socket";
          ReloadPropagatedFrom = "podman.socket";
        };
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
