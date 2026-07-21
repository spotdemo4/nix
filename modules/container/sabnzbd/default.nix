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
  cfg = config.trev.containers.sabnzbd;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } quadletNetworks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } quadletNetworks;
in
{
  options.trev.containers.sabnzbd = {
    enable = mkEnableOption "SABnzbd container";
    image = mkImageOption "lscr.io/linuxserver/sabnzbd:5.0.4@sha256:b67039e6739c2379f2eac8901248cdfcd78536ee34fe6948faea6b8ce8b4805b";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by SABnzbd.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by SABnzbd.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by SABnzbd.";
    };
    downloadPath = mkOption {
      type = types.str;
      default = "/mnt/pool/download/sabnzbd";
      description = "Host path for SABnzbd downloads.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "sabnzbd.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for SABnzbd.";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "SABnzbd port published on the host.";
    };
    networks = networks // {
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
        message = "trev.containers.sabnzbd requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.sabnzbd requires trev.containers.radarr.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.sabnzbd.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes.sabnzbd.ref}:/config"
          "${cfg.downloadPath}:/pool/download/sabnzbd"
        ];
        publishPorts = [ (toString cfg.port) ];
        networks = cfg.networks;
        labels = {
          traefik = {
            enable = true;
            http.routers.sabnzbd = {
              rule = "HostRegexp(`${cfg.domainPattern}`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };

      volumes.sabnzbd = { };
    };
  };
}
