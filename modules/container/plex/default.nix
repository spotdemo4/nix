{
  lib,
  config,
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
  cfg = config.trev.containers.plex;
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.plex = {
    enable = mkEnableOption "Plex container";
    image = containerOptions.mkImageOption "lscr.io/linuxserver/plex:1.43.2@sha256:12008668bf8b79c6ffeb0c0a7878a0354aaaa032368da71a0ea5e84717453b11";
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
    domainPattern = mkOption {
      type = types.str;
      default = "plex.trev.(xyz|zip|kiwi)";
      description = "Traefik HostRegexp pattern for Plex.";
    };
    port = mkOption {
      type = types.port;
      default = 32400;
      description = "Plex port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.plex.containerConfig = {
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
        publishPorts = [ (toString cfg.port) ];
        networks = [ config.virtualisation.quadlet.networks.plex.ref ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            tcp.routers.plex = {
              rule = "HostSNI(`*`)";
              entryPoints = "plex";
            };
            http.routers.plex.rule = "HostRegexp(`${cfg.domainPattern}`)";
          };
        };
      };

      volumes.plex = { };
      networks.plex = { };
    };
  };
}
