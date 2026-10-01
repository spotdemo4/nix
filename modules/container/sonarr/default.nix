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
    mkContainer
    mkImageOption
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.sonarr;
in
{
  options.trev.containers.sonarr = {
    enable = mkEnableOption "Sonarr container";
    image = mkImageOption "lscr.io/linuxserver/sonarr:4.0.20@sha256:f247545d23ba8b233d6604575347e48a623fe6ad75dda02348bf81917f3b5c06";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Sonarr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Sonarr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Sonarr.";
    };
    poolPath = mkOption {
      type = types.str;
      default = "/mnt/pool";
      description = "Host media pool path.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "sonarr.trev.zip"
        "sonarr.trev.kiwi"
      ];
      description = "Domains routed to Sonarr.";
    };
    port = mkOption {
      type = types.port;
      default = 8989;
      description = "Sonarr port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.sonarr = {
      inherit (cfg) domains port;
      auth = "admin";
    };

    virtualisation.quadlet = {
      containers.sonarr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes.sonarr.ref}:/config"
          "${cfg.poolPath}:/pool"
        ];
        publishPorts = [ "${toString cfg.port}:8989" ];
        networks = [ config.virtualisation.quadlet.networks.sonarr.ref ];
      };

      volumes.sonarr = { };
      networks.sonarr = { };
    };
  };
}
