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
  cfg = config.trev.containers.prowlarr;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } networks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } networks;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.prowlarr = {
    enable = mkEnableOption "Prowlarr container";
    image = containerOptions.mkImageOption "lscr.io/linuxserver/prowlarr:2.4.0@sha256:4fd7a166c8f46dd3370a871c250ee577d6c2ae97a0dbe0e3614b5ef736205620";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Prowlarr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Prowlarr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Prowlarr.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "prowlarr.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for Prowlarr.";
    };
    port = mkOption {
      type = types.port;
      default = 9696;
      description = "Prowlarr port published on the host.";
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
        message = "trev.containers.prowlarr requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.prowlarr requires trev.containers.radarr.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.prowlarr.containerConfig = {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [ "${volumes.prowlarr.ref}:/config" ];
        publishPorts = [ (toString cfg.port) ];
        networks = cfg.networks;
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.prowlarr = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };

      volumes.prowlarr = { };
    };
  };
}
