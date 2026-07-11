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
    image = containerOptions.mkImageOption "lscr.io/linuxserver/qbittorrent:latest@sha256:2e074403c7b72e6d89cee3d0d41a47f7b5708c6a9e5316f3958c90765cbe12ce";
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
    protonVpnSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/protonvpn-qbittorrent.age;
      description = "Age file containing the Proton VPN WireGuard private key.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.qbittorrent requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.qbittorrent.enable = true";
      }
    ];

    secrets.protonvpn-qbittorrent.file = cfg.protonVpnSecretFile;

    virtualisation.quadlet = {
      containers.qbittorrent = {
        containerConfig = {
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
          labels = (import (self + /lib/label)) {
            attrs.traefik = {
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
