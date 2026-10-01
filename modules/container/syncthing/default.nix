{
  self,
  config,
  lib,
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
  cfg = config.trev.containers.syncthing;
in
{
  options.trev.containers.syncthing = {
    enable = mkEnableOption "Syncthing container";
    image = mkImageOption "docker.io/syncthing/syncthing:2.1.5@sha256:397aa00b92b48d65540ea3ae3cbf271b87bdccbe07a0b7bd7d2debc3a7b29138";

    domain = mkOption {
      type = types.str;
      default = "syncthing.trev.zip";
      description = "Domain routed to the Syncthing web UI.";
    };

    hostname = mkOption {
      type = types.str;
      default = "syncthing";
      description = "Hostname assigned to the Syncthing container.";
    };

    userId = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Syncthing.";
    };

    groupId = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Syncthing.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes = {
      syncthing = {
        domains = [ cfg.domain ];
        port = 8384;
        auth = "trev";
      };
      syncthing-tcp = {
        protocol = "tcp";
        port = 22000;
      };
      syncthing-udp = {
        protocol = "udp";
        port = 22000;
      };
    };

    virtualisation.quadlet = {
      containers.syncthing.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        hostname = cfg.hostname;
        environments = {
          PUID = toString cfg.userId;
          PGID = toString cfg.groupId;
          STGUIADDRESS = "0.0.0.0:8384";
        };
        volumes = [
          "${volumes.syncthing.ref}:/var/syncthing"
        ];
        publishPorts = [
          "8384:8384"
          "22000:22000/tcp"
          "22000:22000/udp"
        ];
        networks = [
          networks.syncthing.ref
        ];
        healthCmd = "curl -fkLsS -m 2 127.0.0.1:8384/rest/noauth/health | grep -q OK || exit 1";
        healthInterval = "1m";
        healthTimeout = "10s";
        healthRetries = 3;
      };

      volumes.syncthing = { };
      networks.syncthing = { };
    };
  };
}
