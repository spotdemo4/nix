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
  cfg = config.trev.containers.syncthing;
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  options.trev.containers.syncthing = {
    enable = mkEnableOption "Syncthing container";
    image = mkImageOption "docker.io/syncthing/syncthing:2.1.2@sha256:4464f4161dd0251e20d46bb3aec83363db75d80cef1abdd5d5fd4054b04a004d";

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
        labels = {
          traefik = {
            enable = true;
            http = {
              routers.syncthing = {
                rule = "Host(`${cfg.domain}`)";
                middlewares = "secure-trev@file";
              };
              services.syncthing.loadbalancer.server.port = 8384;
            };
            tcp = {
              routers.syncthing = {
                rule = "HostSNI(`*`)";
                entryPoints = "syncthing-tcp";
                service = "syncthing";
              };
              services.syncthing.loadbalancer.server.port = 22000;
            };
            udp = {
              routers.syncthing = {
                entryPoints = "syncthing-udp";
                service = "syncthing";
              };
              services.syncthing.loadbalancer.server.port = 22000;
            };
          };
        };
      };

      volumes.syncthing = { };
      networks.syncthing = { };
    };
  };
}
