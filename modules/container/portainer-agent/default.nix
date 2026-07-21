{
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
  inherit (import ../../../lib/container-options.nix { inherit lib; })
    mkImageOption
    ;
  cfg = config.trev.containers.portainer-agent;
in
{
  options.trev.containers.portainer-agent = {
    enable = mkEnableOption "the Portainer Agent container";
    image = mkImageOption "docker.io/portainer/agent:2.43.0@sha256:3e8cb049fc5fe8f7328dec3d5312d7da3f007127eb6f78f98f3e883d7c15e4b4";

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
