{
  lib,
  config,
  ...
}: {
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
        image = "ghcr.io/spotdemo4/traefik-kop:0.0.4-next-b0db12c-amd64@sha256:3416dab4056779032984bf05c242c0fb62cdd194a4d3823d0f688640e89b2e96";
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
      };
    };
  };
}
