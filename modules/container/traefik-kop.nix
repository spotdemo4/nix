{
  lib,
  config,
  ...
}: {
  options.traefik-kop = {
    enable = lib.mkEnableOption "enable update script";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The IP address of the client
      '';
    };
  };

  config = lib.mkIf config.update.enable {
    virtualisation.oci-containers.containers = {
      traefik-kop = {
        image = "ghcr.io/jittering/traefik-kop:latest";
        pull = "newer";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
        ];
        environment = {
          REDIS_ADDR = "10.10.10.105:6379";
          BIND_IP = "${config.traefik-kop.ip}";
        };
      };
    };
  };
}
