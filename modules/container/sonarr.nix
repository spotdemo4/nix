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
      image = "lscr.io/linuxserver/sonarr:4.0.15@sha256:fbe67c25693dc5f3de220c5691f374576ae265df782c16918cc071b630490bd7";
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
