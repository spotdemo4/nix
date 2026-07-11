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
  cfg = config.trev.containers.bazarr;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } networks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } networks;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.bazarr = {
    enable = mkEnableOption "Bazarr container";
    image = containerOptions.mkImageOption "lscr.io/linuxserver/bazarr:1.6.0@sha256:5d916d07404296ec35ee726e13e0e558f05952724cf494a7f009d913fb2b12f3";
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
    domainPattern = mkOption {
      type = types.str;
      default = "bazarr.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Bazarr.";
    };
    port = mkOption {
      type = types.port;
      default = 6767;
      description = "Bazarr port published on the host.";
    };
    networks = containerOptions.networks // {
      default = [
        sonarrNetwork.ref
        radarrNetwork.ref
      ];
    };
  };

  config = mkIf cfg.enable {
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
      containers.bazarr.containerConfig = {
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
        publishPorts = [ (toString cfg.port) ];
        networks = cfg.networks;
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.bazarr = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };

      volumes.bazarr = { };
    };
  };
}
