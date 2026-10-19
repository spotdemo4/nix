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
    ;
  inherit (config.virtualisation.quadlet)
    networks
    volumes
    ;
  cfg = config.trev.containers.qui;
  qbittorrent = lib.attrByPath [ "trev" "containers" "qbittorrent" ] {
    enable = false;
    downloadPath = "/mnt/pool/download/qbittorrent";
  } config;
in
{
  options.trev.containers.qui = {
    enable = mkEnableOption "qui container";
    image = mkImageOption "ghcr.io/autobrr/qui:v1.33.0@sha256:0348a74d25118969ed31baf5af922685ec03a0ef84af4e01d7c8441bc341d5b8";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by qui.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by qui.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by qui.";
    };
    downloadPath = mkOption {
      type = types.str;
      default = qbittorrent.downloadPath;
      defaultText = lib.literalExpression "config.trev.containers.qbittorrent.downloadPath";
      description = "Host path for qBittorrent downloads, mounted where qBittorrent sees it.";
    };
    domains = mkOption {
      type = types.listOf types.str;
      default = [ "qui.trev.xyz" ];
      description = "Domains routed to qui.";
    };
    port = mkOption {
      type = types.port;
      default = 7476;
      description = "qui port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.qui = {
      inherit (cfg) domains port;
      auth = "trev";
    };

    assertions = [
      {
        assertion = qbittorrent.enable;
        message = "trev.containers.qui requires trev.containers.qbittorrent.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.qui.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timeZone;
          QUI__SESSION_COOKIE_SECURE = "true";
          QUI__CHECK_FOR_UPDATES = "false";
          QUI__DISABLE_SELF_UPDATE = "true";
        };
        volumes = [
          "${volumes.qui.ref}:/config"
          "${cfg.downloadPath}:/pool/download/qbittorrent"
        ];
        publishPorts = [ "${toString cfg.port}:7476" ];
        networks = [ networks.qui.ref ];
      };

      volumes.qui = { };
      networks.qui = { };
    };
  };
}
