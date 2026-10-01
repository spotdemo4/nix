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
  cfg = config.trev.containers.bazarr;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } quadletNetworks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } quadletNetworks;
in
{
  options.trev.containers.bazarr = {
    enable = mkEnableOption "Bazarr container";
    image = mkImageOption "lscr.io/linuxserver/bazarr:1.6.2@sha256:8b30e81c4aec2991f469e78fae8afaa89ecc9b21a80e3897f50427216b55470c";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Bazarr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Bazarr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Bazarr.";
    };
    poolPath = mkOption {
      type = types.str;
      default = "/mnt/pool";
      description = "Host media pool path.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "bazarr.trev.zip"
        "bazarr.trev.kiwi"
      ];
      description = "Domains routed to Bazarr.";
    };
    port = mkOption {
      type = types.port;
      default = 6767;
      description = "Bazarr port published on the host.";
    };
    networks = networks // {
      default = [
        sonarrNetwork.ref
        radarrNetwork.ref
      ];
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.bazarr = {
      inherit (cfg) domains port;
      auth = "admin";
    };

    assertions = [
      {
        assertion = sonarr.enable;
        message = "trev.containers.bazarr requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.bazarr requires trev.containers.radarr.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.bazarr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes.bazarr.ref}:/config"
          "${cfg.poolPath}:/pool"
        ];
        publishPorts = [ "${toString cfg.port}:6767" ];
        networks = cfg.networks;
      };

      volumes.bazarr = { };
    };
  };
}
