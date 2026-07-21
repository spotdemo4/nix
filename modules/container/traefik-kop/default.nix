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
  cfg = config.trev.containers.traefik-kop;
in
{
  options.trev.containers.traefik-kop = {
    enable = mkEnableOption "the Traefik Kop container";
    image = mkImageOption "ghcr.io/jittering/traefik-kop:0.20.1@sha256:f4919330407ae93f6d966cff7d7352198c09ed5e788c959a1bfd9d0eaf7e1091";

    podmanSocket = mkOption {
      type = types.str;
      default = "/run/podman/podman.sock";
      description = "Host Podman socket exposed to Traefik Kop.";
    };

    ip = mkOption {
      type = types.str;
      default = "localhost";
      description = "IP address advertised for this Podman host.";
    };

    serverIp = mkOption {
      type = types.str;
      default = "10.10.10.105:6379";
      description = "Address of the Traefik Redis server.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet.containers.traefik-kop = {
      containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${cfg.podmanSocket}:/var/run/docker.sock"
        ];
        environments = {
          REDIS_ADDR = cfg.serverIp;
          BIND_IP = cfg.ip;
        };
      };

      unitConfig = {
        After = "podman.socket";
        BindsTo = "podman.socket";
        ReloadPropagatedFrom = "podman.socket";

        # Disable rate-limiting restarts
        StartLimitIntervalSec = 0;
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
