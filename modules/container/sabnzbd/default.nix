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
  cfg = config.trev.containers.sabnzbd;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } networks;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } networks;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.sabnzbd = {
    enable = mkEnableOption "SABnzbd container";
    image = containerOptions.mkImageOption "lscr.io/linuxserver/sabnzbd:5.0.4@sha256:b67039e6739c2379f2eac8901248cdfcd78536ee34fe6948faea6b8ce8b4805b";
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
        message = "trev.containers.sabnzbd requires trev.containers.sonarr.enable = true";
      }
      {
        assertion = radarr.enable;
        message = "trev.containers.sabnzbd requires trev.containers.radarr.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.sabnzbd.containerConfig = {
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
        labels = toLabel {
          attrs.traefik = {
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
