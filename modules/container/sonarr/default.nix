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
    image = mkImageOption "lscr.io/linuxserver/sonarr:4.0.19@sha256:373159ba768e23a3a1c497d9f2b936addf8fd5b1fdce7dd6a14080ac928bfda0";
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
    domainPattern = mkOption {
      type = types.str;
      default = "sonarr.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Sonarr.";
    };
    port = mkOption {
      type = types.port;
      default = 8989;
      description = "Sonarr port published on the host.";
    };
  };

  config = mkIf cfg.enable {
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
        publishPorts = [ (toString cfg.port) ];
        networks = [ config.virtualisation.quadlet.networks.sonarr.ref ];
        labels = {
          traefik = {
            enable = true;
            http.routers.sonarr = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };

      volumes.sonarr = { };
      networks.sonarr = { };
    };
  };
}
