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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.rsyncd;
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.rsyncd = {
    enable = mkEnableOption "rsync daemon container";
    image = containerOptions.mkImageOption "docker.io/vimagick/rsyncd:latest@sha256:fb98a50388b111940d0e4cae0b9fd5f1606b970caa713dfb1ec1c680b8290638";

    configFile = mkOption {
      type = types.either types.path types.str;
      default = ./rsyncd.conf;
      description = "rsync daemon configuration mounted into the container.";
    };

    secretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/rsyncd.age;
      description = "Age-encrypted rsync daemon credentials.";
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
    secrets.rsyncd.file = cfg.secretFile;

    virtualisation.quadlet = {
      containers.rsyncd.containerConfig = {
        image = cfg.image;
        pull = "missing";
        secrets = [
          "${secrets.rsyncd.mount},target=/etc/rsyncd.secrets,mode=0400"
        ];
        volumes = [
          "${cfg.configFile}:/etc/rsyncd.conf"
          "${volumes.codex.ref}:/codex"
        ];
        publishPorts = [
          "${toString cfg.port}:${toString cfg.port}"
        ];
        labels = toLabel {
          attrs.traefik = {
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
