{
  config,
  lib,
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
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.rsyncd;
in
{
  options.trev.containers.rsyncd = {
    enable = mkEnableOption "rsync daemon container";
    image = mkImageOption "docker.io/vimagick/rsyncd:latest@sha256:fb98a50388b111940d0e4cae0b9fd5f1606b970caa713dfb1ec1c680b8290638";

    configFile = mkOption {
      type = types.either types.path types.str;
      default = ./rsyncd.conf;
      description = "rsync daemon configuration mounted into the container.";
    };

    secret = mkOption {
      type = secretType;
      default = {
        ref = "rsyncd";
        file = self + /secrets/rsyncd.age;
      };
      description = "rsync daemon credentials secret.";
    };

    tlsDomain = mkOption {
      type = types.str;
      default = "trev.zip";
      description = "TLS SNI domain routed to rsyncd.";
    };

    port = mkOption {
      type = types.port;
      default = 873;
      description = "rsync daemon port to publish.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      secrets.${cfg.secret.ref} = cfg.secret;

      containers.rsyncd.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        secrets = [
          {
            inherit (cfg.secret) ref;
            type = "mount";
            target = "/etc/rsyncd.secrets";
            mode = "0400";
          }
        ];
        volumes = [
          "${cfg.configFile}:/etc/rsyncd.conf"
          "${volumes.codex.ref}:/codex"
        ];
        publishPorts = [
          "${toString cfg.port}:${toString cfg.port}"
        ];
        labels = {
          traefik = {
            enable = true;
            tcp = {
              routers.rsyncd = {
                rule = "HostSNI(`*`)";
                entryPoints = "rsyncd";
                service = "rsyncd";
              };
              routers.rsyncd-tls = {
                rule = "HostSNI(`${cfg.tlsDomain}`)";
                entryPoints = "rsyncd-tls";
                service = "rsyncd";
                tls = "true";
                "tls.certresolver" = "letsencrypt";
              };
              services.rsyncd.loadbalancer.server.port = cfg.port;
            };
          };
        };
      };

      volumes.codex = { };
    };
  };
}
