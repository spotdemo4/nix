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
  cfg = config.trev.containers.seerr;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  plex = lib.attrByPath [ "trev" "containers" "plex" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } quadletNetworks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } quadletNetworks;
  plexNetwork = lib.attrByPath [ "plex" ] { ref = "plex"; } quadletNetworks;
in
{
  options.trev.containers.seerr = {
    enable = mkEnableOption "Seerr container";
    image = mkImageOption "ghcr.io/seerr-team/seerr:v3.5.0@sha256:27602401178d54f1964442287b9f23f67a3fa2252645ee8065839ea1c3f69e45";
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Seerr.";
    };
    logLevel = mkOption {
      type = types.str;
      default = "debug";
      description = "Seerr log level.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [
        "overseerr.trev.xyz"
        "seerr.trev.xyz"
      ];
      description = "Domains routed to Seerr.";
    };
    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Seerr port published on the host.";
    };
    networks = networks // {
      default = [
        sonarrNetwork.ref
        radarrNetwork.ref
        plexNetwork.ref
      ];
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.seerr = {
      inherit (cfg) domains port;
    };

    assertions = [
      {
        assertion = sonarr.enable;
        message = "trev.containers.seerr requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.seerr requires trev.containers.radarr.enable = true";
      }
      {
        assertion = plex.enable;
        message = "trev.containers.seerr requires trev.containers.plex.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.seerr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          LOG_LEVEL = cfg.logLevel;
          TZ = cfg.timeZone;
        };
        volumes = [ "${volumes.seerr.ref}:/app/config" ];
        publishPorts = [ "${toString cfg.port}:5055" ];
        networks = cfg.networks;
      };

      volumes.seerr = { };
    };
  };
}
