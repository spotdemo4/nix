{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:4.0.15@sha256:1a90192952c30f9420994b2e2171083ea8cae100357de5e9eb25890efa90a6ce";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.sonarr.ref}:/config"
        "/mnt/pool/shows:/shows"
        "/mnt/pool/qbittorrent-data/downloads:/qbittorrent/downloads"
        "/mnt/pool/sabnzbd-data/downloads:/sabnzbd/downloads"
      ];
      publishPorts = [
        "8989"
      ];
      networks = [
        networks."sonarr".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.sonarr = {
              rule = "HostRegexp(`sonarr.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker,header-basic@file";
            };
          };
        };
      };
    };

    volumes = {
      sonarr = {};
    };

    networks = {
      sonarr = {};
    };
  };
}
