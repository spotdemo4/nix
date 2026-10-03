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
    networks
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.tautulli;
  plex = lib.attrByPath [ "trev" "containers" "plex" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  plexNetwork = lib.attrByPath [ "plex" ] { ref = "plex"; } quadletNetworks;
in
{
  options.trev.containers.tautulli = {
    enable = mkEnableOption "Tautulli container";
    image = mkImageOption "lscr.io/linuxserver/tautulli:latest@sha256:bfcd2f3f6f89d2171d161ac1780723d1633f8de3c4c993d0dc52aa9edb729e16";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Tautulli.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Tautulli.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Tautulli.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "tautulli.trev.zip"
        "tautulli.trev.kiwi"
      ];
      description = "Domains routed to Tautulli.";
    };
    port = mkOption {
      type = types.port;
      default = 8181;
      description = "Tautulli port published on the host.";
    };
    networks = networks // {
      default = [ plexNetwork.ref ];
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.tautulli = {
      inherit (cfg) domains port;
      auth = "trev";
    };

    assertions = [
      {
        assertion = plex.enable;
        message = "trev.containers.tautulli requires trev.containers.plex.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.tautulli.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [ "${volumes.tautulli.ref}:/config" ];
        publishPorts = [ "${toString cfg.port}:8181" ];
        networks = cfg.networks;
      };

      volumes.tautulli = { };
    };
  };
}
