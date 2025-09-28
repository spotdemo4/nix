{
  config,
  self,
  pkgs,
  ...
}: let
  inherit (config.virtualisation.quadlet) containers networks volumes;
  inherit (config) gluetun;
  toLabel = import (self + /modules/util/label);
in {
  imports = [./gluetun.nix];

  secrets = {
    "protonvpn-qbittorrent".file = self + /secrets/protonvpn-qbittorrent.age;
    "password".file = self + /secrets/password.age;
  };

  gluetun."qbittorrent" = {
    secret = config.secrets."protonvpn-qbittorrent";
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
      qbittorrent = {
        containerConfig = {
          image = "lscr.io/linuxserver/qbittorrent:latest@sha256:5f3785f8d8cd27d509cd948a06195306c3d951b1e1e123e46c7be40ecfb6965f";
          pull = "missing";
          environments = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/Detroit";
            WEBUI_PORT = "8185";
            DOCKER_MODS = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
          };
          volumes = [
            "${volumes."qbittorrent".ref}:/config"
            "/mnt/pool/download/qbittorrent:/pool/download/qbittorrent"
          ];
          networks = [
            "container:${gluetun."qbittorrent".ref}"
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

        unitConfig = {
          After = containers."gluetun-qbittorrent".ref;
          BindsTo = containers."gluetun-qbittorrent".ref;
          ReloadPropagatedFrom = containers."gluetun-qbittorrent".ref;
        };
      };

      qbittorrent-ports = {
        containerConfig = {
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
            "container:${gluetun."qbittorrent".ref}"
          ];
        };

        unitConfig = {
          After = containers."gluetun-qbittorrent".ref;
          BindsTo = containers."gluetun-qbittorrent".ref;
          ReloadPropagatedFrom = containers."gluetun-qbittorrent".ref;
        };
      };

      qbittorrent-manager.containerConfig = let
        configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
          qbt = {
            host = "gluetun-qbittorrent:8185";
            user = "!ENV QBIT_USER";
            pass = "!ENV QBIT_PASS";
          };
          directory = {
            root_dir = "/pool/download/qbittorrent/complete";
            torrents_dir = "/pool/download/qbittorrent/torrents";
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
        image = "ghcr.io/stuffanthings/qbit_manage:v4.6.3@sha256:64f749b97604d607747fc8b790821cf0317d8107385ea111afe1ed1c9d1d5b11";
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
          "/mnt/pool/download/qbittorrent:/pool/download/qbittorrent"
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
