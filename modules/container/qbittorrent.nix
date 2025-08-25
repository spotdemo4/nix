{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
in {
  imports = [./gluetun.nix];

  secrets."qbittorrent-wg".file = self + /secrets/qbittorrent-wg.age;

  gluetun."qbittorrent" = {
    ports = ["8185"];
    labels = {
      traefik = {
        enable = true;
        http.routers.gluetun-qbittorrent = {
          rule = "HostRegexp(`qbittorrent.trev.(zip|kiwi)`)";
          middlewares = "auth-github@docker";
        };
      };
    };
    secret = config.secrets."qbittorrent-wg";
  };

  virtualisation.quadlet = {
    containers.qbittorrent.containerConfig = {
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
    };

    volumes = {
      qbittorrent = {};
    };
  };
}
