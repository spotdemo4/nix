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
  cfg = config.trev.containers.radarr;
in
{
  options.trev.containers.radarr = {
    enable = mkEnableOption "Radarr container";
    image = mkImageOption "lscr.io/linuxserver/radarr:6.3.0@sha256:a45b5ab0f850f39edb4cc9c95bbd967b52ddc3d4574a4dfb45561177db6c88f4";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Radarr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Radarr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Radarr.";
    };
    poolPath = mkOption {
      type = types.str;
      default = "/mnt/pool";
      description = "Host media pool path.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "radarr.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Radarr.";
    };
    port = mkOption {
      type = types.port;
      default = 7878;
      description = "Radarr port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.radarr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes.radarr.ref}:/config"
          "${cfg.poolPath}:/pool"
        ];
        publishPorts = [ (toString cfg.port) ];
        networks = [ config.virtualisation.quadlet.networks.radarr.ref ];
        labels = {
          traefik = {
            enable = true;
            http.routers.radarr = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };

      volumes.radarr = { };
      networks.radarr = { };
    };
  };
}
