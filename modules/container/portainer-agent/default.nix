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
    mkImageOption
    ;
  cfg = config.trev.containers.portainer-agent;
in
{
  options.trev.containers.portainer-agent = {
    enable = mkEnableOption "the Portainer Agent container";
    image = mkImageOption "docker.io/portainer/agent:3.0.0@sha256:cd22e4f904ff0e957a1421d1e9e9b8ca0523ed6b5f79f4d12b2ed0809ef3d734";

    podmanSocket = mkOption {
      type = types.str;
      default = "/run/podman/podman.sock";
      description = "Host Podman socket exposed to Portainer Agent.";
    };

    containerStoragePath = mkOption {
      type = types.str;
      default = "/var/lib/containers/storage";
      description = "Host container storage exposed to Portainer Agent.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "9001:9001" ];
      description = "Ports to publish from Portainer Agent.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet.containers.portainer-agent = {
      containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${cfg.podmanSocket}:/var/run/docker.sock"
          "${cfg.containerStoragePath}:/var/lib/docker/volumes"
        ];
        publishPorts = cfg.publishPorts;
      };

      unitConfig = {
        After = "podman.socket";
        BindsTo = "podman.socket";
        ReloadPropagatedFrom = "podman.socket";
      };
    };
  };
}
