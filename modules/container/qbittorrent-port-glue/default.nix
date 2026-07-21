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
    mkImageOption
    ;
  cfg = config.trev.containers.qbittorrent-port-glue;
  gluetunConfig = lib.attrByPath [ "trev" "containers" "gluetun" ] {
    enable = false;
    instances = { };
  } config;
  gluetun = lib.attrByPath [ "instances" "qbittorrent" ] {
    enable = false;
    ref = "gluetun-qbittorrent";
    volumeName = "gluetun-qbittorrent";
  } gluetunConfig;
  qbittorrent = lib.attrByPath [ "trev" "containers" "qbittorrent" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) containers volumes;
  gluetunVolume = lib.attrByPath [ gluetun.volumeName ] { ref = gluetun.volumeName; } volumes;
  qbittorrentContainer = lib.attrByPath [ "qbittorrent" ] { ref = "qbittorrent"; } containers;
in
{
  options.trev.containers.qbittorrent-port-glue = {
    enable = mkEnableOption "qBittorrent port glue container";
    image = mkImageOption "ghcr.io/spotdemo4/qbittorrent-port-glue:0.1.1@sha256:28587cf6c7b28ed3e8464a36f476ea11881e8a0a204cdaae852f0f438f8c7cc1";
    qbittorrentHost = mkOption {
      type = types.str;
      default = "http://localhost";
      description = "qBittorrent host used by the port glue.";
    };
    qbittorrentPort = mkOption {
      type = types.port;
      default = 8185;
      description = "qBittorrent Web UI port used by the port glue.";
    };
    qbittorrentUser = mkOption {
      type = types.str;
      default = "trev";
      description = "qBittorrent user used by the port glue.";
    };
    portFile = mkOption {
      type = types.str;
      default = "/tmp/gluetun/forwarded_port";
      description = "Container path to Gluetun's forwarded port file.";
    };
    passwordSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/password.age;
      description = "Age file containing the qBittorrent password.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.qbittorrent-port-glue requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.qbittorrent.enable = true";
      }
      {
        assertion = qbittorrent.enable;
        message = "trev.containers.qbittorrent-port-glue requires trev.containers.qbittorrent.enable = true";
      }
    ];

    secrets.password.file = cfg.passwordSecretFile;

    virtualisation.quadlet.containers.qbittorrent-port-glue = {
      containerConfig = {
        image = cfg.image;
        pull = "missing";
        environments = {
          QBITTORRENT_HOST = cfg.qbittorrentHost;
          QBITTORRENT_PORT = toString cfg.qbittorrentPort;
          QBITTORRENT_USER = cfg.qbittorrentUser;
          PORT_FILE = cfg.portFile;
        };
        secrets = [ "${config.secrets.password.env},target=QBITTORRENT_PASS" ];
        volumes = [ "${gluetunVolume.ref}:/tmp/gluetun" ];
        networks = [ "container:${gluetun.ref}" ];
      };

      unitConfig = {
        BindsTo = qbittorrentContainer.ref;
        After = qbittorrentContainer.ref;
        ReloadPropagatedFrom = qbittorrentContainer.ref;
      };
    };
  };
}
