{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
in {
  imports = [./gluetun.nix ./utils/secret.nix];

  secrets = {
    enable = true;
    secret."qbittorrent-wg" = self + /secrets/qbittorrent-wg;
  };

  virtualisation.quadlet = {
    containers.qbittorrent.containerConfig = {
      image = "ghcr.io/hotio/qbittorrent:latest@sha256:7305ff2ca6684d25a1648a2857f5ffab098f46b725ecad9e6ab65bd4111aaa9f ";
      pull = "missing";
      environments = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
        WEBUI_PORTS = "8185/tcp,8185/udp";
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

  gluetun = {
    enable = true;
    name = "qbittorrent";
    ports = ["8185"];
    privateKeySecret = "qbittorrent-wg";
    labels = {
      traefik = {
        enable = true;
        http.routers.gluetun-qbittorrent = {
          rule = "HostRegexp(`qbittorrent.trev.(zip|kiwi)`)";
          middlewares = "auth-github@docker";
        };
      };
    };
  };
}
