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
    ../gluetun.nix
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
        image = "lscr.io/linuxserver/qbittorrent:latest@sha256:dfa75bc534ad4f36262f75b5c1d4c4f0ddd5e7ed5711ebc581c70920cce204ee";
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
        After = containers."gluetun-qbittorrent".ref;
        BindsTo = containers."gluetun-qbittorrent".ref;
        ReloadPropagatedFrom = containers."gluetun-qbittorrent".ref;
      };
    };

    volumes = {
      qbittorrent = { };
    };
  };
}
