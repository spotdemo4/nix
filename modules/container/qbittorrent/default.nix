{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks volumes;
  inherit (config) gluetun;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/gluetun)
    ./ports.nix
  ];

  secrets = {
    "protonvpn-qbittorrent".file = self + /secrets/protonvpn-qbittorrent.age;
    "password".file = self + /secrets/password.age;
  };

  gluetun."qbittorrent" = {
    secret = config.secrets."protonvpn-qbittorrent";
    ports = [ "8185" ];
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
    containers.qbittorrent = {
      containerConfig = {
        image = "lscr.io/linuxserver/qbittorrent:latest@sha256:85eb27d2d09cd4cb748036a4c7f261321da516b6f88229176cf05a92ccd26815";
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
          attrs.traefik = {
            enable = true;
            http.routers.qbittorrent = {
              rule = "HostRegexp(`qbittorrent.trev.(zip|kiwi)`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };

      unitConfig = {
        BindsTo = containers."gluetun-qbittorrent".ref;
        After = containers."gluetun-qbittorrent".ref;
        ReloadPropagatedFrom = containers."gluetun-qbittorrent".ref;
      };
    };

    volumes = {
      qbittorrent = { };
    };
  };
}
