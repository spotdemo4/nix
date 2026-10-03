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
  cfg = config.trev.containers.plex;
in
{
  options.trev.containers.plex = {
    enable = mkEnableOption "Plex container";
    image = mkImageOption "lscr.io/linuxserver/plex:1.43.4@sha256:3f71bd6eb6a4478ac19b11c5d0ba9746a5eacad1976f9b99ed4a2c21767e57bb";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Plex.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Plex.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Plex.";
    };
    devices = mkOption {
      type = types.listOf types.str;
      default = [
        "/dev/dri/card0:/dev/dri/card0"
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];
      description = "Host devices exposed to Plex.";
    };
    moviesPath = mkOption {
      type = types.str;
      default = "/mnt/pool/movies";
      description = "Host movie library path.";
    };
    showsPath = mkOption {
      type = types.str;
      default = "/mnt/pool/shows";
      description = "Host television library path.";
    };
    musicPath = mkOption {
      type = types.str;
      default = "/mnt/pool/music";
      description = "Host music library path.";
    };
    transcodePath = mkOption {
      type = types.str;
      default = "/mnt/fast/plex-data";
      description = "Host Plex transcode path.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "plex.trev.xyz"
        "plex.trev.zip"
        "plex.trev.kiwi"
      ];
      description = "Domains routed to Plex.";
    };
    port = mkOption {
      type = types.port;
      default = 32400;
      description = "Plex port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes = {
      plex = {
        inherit (cfg) domains port;
      };
      plex-tcp = {
        protocol = "tcp";
        inherit (cfg) port;
        listen = 32400;
      };
    };

    virtualisation.quadlet = {
      containers.plex.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        devices = cfg.devices;
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
          VERSION = "docker";
        };
        volumes = [
          "${volumes.plex.ref}:/config"
          "${cfg.moviesPath}:/movies"
          "${cfg.showsPath}:/shows"
          "${cfg.musicPath}:/music"
          "${cfg.transcodePath}:/transcode"
        ];
        publishPorts = [ "${toString cfg.port}:32400" ];
        networks = [ config.virtualisation.quadlet.networks.plex.ref ];
      };

      volumes.plex = { };
      networks.plex = { };
    };
  };
}
