{
  config,
  self,
  pkgs,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  imports = [./gluetun.nix];

  secrets = {
    "qbittorrent-wg".file = self + /secrets/qbittorrent-wg.age;
    "password".file = self + /secrets/password.age;
  };

  gluetun."qbittorrent" = {
    secret = config.secrets."qbittorrent-wg";
    ports = ["8185"];
    environments = {
      VPN_SERVICE_PROVIDER = "protonvpn";
      VPN_TYPE = "wireguard";
      SERVER_CITIES = "Chicago,Toronto";
      PORT_FORWARD_ONLY = "on";
      VPN_PORT_FORWARDING = "on";
    };
    networks = [
      networks."sonarr".ref
      networks."radarr".ref
    ];
  };

  virtualisation.quadlet = {
    containers = {
      qbittorrent.containerConfig = {
        image = "lscr.io/linuxserver/qbittorrent:5.1.2@sha256:ebfd00848045b30298bcb43627e24bd98ff2bbf584d9b3e62257586de85bcb15";
        pull = "missing";
        environments = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Detroit";
          WEBUI_PORT = "8185";
          DOCKER_MODS = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
        };
        volumes = [
          "${volumes.qbittorrent.ref}:/config"
          "/mnt/pool/qbittorrent-data/downloads:/qbittorrent/downloads"
          "/mnt/pool/qbittorrent-data/torrents:/qbittorrent/torrents"
        ];
        networks = [
          "container:gluetun-qbittorrent"
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http.routers.qbittorrent = {
                rule = "HostRegexp(`qbittorrent.trev.(zip|kiwi)`)";
                middlewares = "auth-github@docker";
              };
            };
          };
        };
      };

      qbittorrent-ports.containerConfig = {
        image = "docker.io/snoringdragon/gluetun-qbittorrent-port-manager:1.3@sha256:679b7a92c494f93b78ad37ef24f3a261e73d0a1a52505ad4f1e39580eedfa14f";
        pull = "missing";
        environments = {
          QBITTORRENT_SERVER = "localhost";
          QBITTORRENT_PORT = "8185";
          QBITTORRENT_USER = "trev";
          PORT_FORWARDED = "/tmp/gluetun/forwarded_port";
          HTTP_S = "http";
        };
        secrets = [
          "${config.secrets."password".env},target=QBITTORRENT_PASS"
        ];
        volumes = [
          "${volumes."gluetun-qbittorrent".ref}:/tmp/gluetun"
        ];
        networks = [
          "container:gluetun-qbittorrent"
        ];
      };

      qbittorrent-manager.containerConfig = let
        configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
          qbt = {
            host = "qbittorrent:8185";
            user = "!ENV QBIT_USER";
            pass = "!ENV QBIT_PASS";
          };
          directory = {
            root_dir = "/qbittorrent/downloads";
            torrents_dir = "/qbittorrent/torrents";
          };
          cat = {
            Uncategorized = "/qbittorrent/downloads";
          };
          recyclebin.enabled = false;
          tracker = {
            other.tag = "other";
          };
        };
      in {
        image = "ghcr.io/stuffanthings/qbit_manage:v4.5.5@sha256:2e582501805b159b0378f259d9de9dca5155a3e444d080c8b00e00ac8c670541";
        pull = "missing";
        environments = {
          QBT_WEB_SERVER = "true";
          QBT_PORT = "8080";
          QBT_CONFIG = "config.yaml";
          QBIT_USER = "trev";
        };
        secrets = [
          "${config.secrets."password".env},target=QBIT_PASS"
        ];
        publishPorts = [
          "8080"
        ];
        volumes = [
          "${volumes.qbittorrent-manager.ref}:/config"
          "${configFile}:/config/config.yaml"
          "/mnt/pool/qbittorrent-data/downloads:/qbittorrent/downloads"
          "/mnt/pool/qbittorrent-data/torrents:/qbittorrent/torrents"
        ];
        networks = [
          networks."sonarr".ref
          networks."radarr".ref
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http.routers.qbitmanage = {
                rule = "HostRegexp(`qbitmanage.trev.(zip|kiwi)`)";
                middlewares = "auth-github@docker";
              };
            };
          };
        };
      };
    };

    volumes = {
      qbittorrent = {};
      qbittorrent-manager = {};
    };
  };
}
