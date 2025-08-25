{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in {
  imports = [./gluetun.nix];

  secrets."qbittorrent-wg".file = self + /secrets/qbittorrent-wg.age;

  gluetun."qbittorrent" = {
    secret = config.secrets."qbittorrent-wg";
    ports = ["8185"];
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
          "/mnt/pool/qbittorrent-data/downloads:/qbittorrent-downloads"
          "/mnt/pool/qbittorrent-data/torrents:/torrents"
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

      qbitmanage.containerConfig = {
        image = "ghcr.io/stuffanthings/qbit_manage:v4.5.5@sha256:2e582501805b159b0378f259d9de9dca5155a3e444d080c8b00e00ac8c670541";
        pull = "missing";
        environments = {
          QBT_WEB_SERVER = "true";
          QBT_PORT = "8080";
        };
        publishPorts = [
          "8080"
        ];
        volumes = [
          "${volumes.qbitmanage.ref}:/config"
          "/mnt/pool/qbittorrent-data/downloads:/qbittorrent-downloads"
          "/mnt/pool/qbittorrent-data/torrents:/torrents"
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
      qbitmanage = {};
    };
  };
}
