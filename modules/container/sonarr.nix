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
      image = "lscr.io/linuxserver/sonarr:4.0.16@sha256:4b8a853b76337cd5de5f69961e23b7d0792ce7bf0a8be083dd7202ef670bfc34";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.sonarr.ref}:/config"
        "/mnt/pool:/pool"
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
