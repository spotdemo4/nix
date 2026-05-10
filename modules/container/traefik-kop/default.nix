{
  lib,
  config,
  ...
}:
{
  options.traefik-kop = {
    enable = lib.mkEnableOption "enable traefik kop";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The IP address of the client
      '';
    };

    server_ip = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.105:6379";
      description = ''
        The IP address of the server
      '';
    };
  };

  config = lib.mkIf config.update.enable {
    virtualisation.quadlet.containers.traefik-kop = {
      containerConfig = {
        image = "ghcr.io/jittering/traefik-kop:0.20.0@sha256:ad6b4b997001b1e43c5a98c1efa75a625968d2435ecb81094bf58ef280aa164c";
        pull = "missing";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
        ];
        environments = {
          REDIS_ADDR = "${config.traefik-kop.server_ip}";
          BIND_IP = "${config.traefik-kop.ip}";
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
