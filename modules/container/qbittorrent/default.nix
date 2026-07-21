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
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  cfg = config.trev.containers.qbittorrent;
  gluetunConfig = lib.attrByPath [ "trev" "containers" "gluetun" ] {
    enable = false;
    instances = { };
  } config;
  gluetun = lib.attrByPath [ "instances" "qbittorrent" ] {
    enable = false;
    ref = "gluetun-qbittorrent";
  } gluetunConfig;
  inherit (config.virtualisation.quadlet) containers volumes;
  gluetunContainer = lib.attrByPath [ gluetun.ref ] { ref = gluetun.ref; } containers;
in
{
  options.trev.containers.qbittorrent = {
    enable = mkEnableOption "qBittorrent container";
    image = mkImageOption "lscr.io/linuxserver/qbittorrent:latest@sha256:b024436f8ca665d16d9a997d26fd27fdf867ee5566ba09f32764e7b2976d3e02";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by qBittorrent.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by qBittorrent.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by qBittorrent.";
    };
    downloadPath = mkOption {
      type = types.str;
      default = "/mnt/pool/download/qbittorrent";
      description = "Host path for qBittorrent downloads.";
    };
    domainPattern = mkOption {
      type = types.str;
      default = "qbittorrent.trev.(zip|kiwi)";
      description = "Traefik HostRegexp pattern for qBittorrent.";
    };
    webUiPort = mkOption {
      type = types.port;
      default = 8185;
      description = "qBittorrent Web UI port.";
    };
    dockerMods = mkOption {
      type = types.str;
      default = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
      description = "LinuxServer Docker mods enabled for qBittorrent.";
    };
    protonVpnSecret = mkOption {
      type = secretType;
      default = {
        ref = "protonvpn-qbittorrent";
        file = self + /secrets/protonvpn-qbittorrent.age;
      };
      description = "Proton VPN WireGuard private key secret.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.qbittorrent requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.qbittorrent.enable = true";
      }
    ];

    virtualisation.quadlet = {
      secrets.${cfg.protonVpnSecret.ref} = cfg.protonVpnSecret;

      containers.qbittorrent = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          environments = {
            PUID = toString cfg.uid;
            PGID = toString cfg.gid;
            TZ = cfg.timeZone;
            WEBUI_PORT = toString cfg.webUiPort;
            DOCKER_MODS = cfg.dockerMods;
          };
          volumes = [
            "${volumes.qbittorrent.ref}:/config"
            "${cfg.downloadPath}:/pool/download/qbittorrent"
          ];
          networks = [ "container:${gluetun.ref}" ];
          labels = {
            traefik = {
              enable = true;
              http.routers.qbittorrent = {
                rule = "HostRegexp(`${cfg.domainPattern}`)";
                middlewares = "secure-trev@file";
              };
            };
          };
        };

        unitConfig = {
          BindsTo = gluetunContainer.ref;
          After = gluetunContainer.ref;
          ReloadPropagatedFrom = gluetunContainer.ref;
        };

        serviceConfig.RestartSec = "20s";
      };

      volumes.qbittorrent = { };
    };
  };
}
