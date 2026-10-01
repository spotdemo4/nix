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
    image = mkImageOption "lscr.io/linuxserver/radarr:6.4.4@sha256:adb6c09d6b729ea5e642c99cea35af72702ef476bf4763f153299ac5db9f0b4f";
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
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "radarr.trev.zip"
        "radarr.trev.kiwi"
      ];
      description = "Domains routed to Radarr.";
    };
    port = mkOption {
      type = types.port;
      default = 7878;
      description = "Radarr port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.radarr = {
      inherit (cfg) domains port;
      auth = "admin";
    };

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
        publishPorts = [ "${toString cfg.port}:7878" ];
        networks = [ config.virtualisation.quadlet.networks.radarr.ref ];
      };

      volumes.radarr = { };
      networks.radarr = { };
    };
  };
}
