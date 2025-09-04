{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:5.27.5@sha256:3ebb31bce86870dbcc15a5db3fba8864e302310cb2adb70476b0b64c1b3dc6dc";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.radarr.ref}:/config"
        "/mnt/pool:/pool"
      ];
      publishPorts = [
        "7878"
      ];
      networks = [
        networks."radarr".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.radarr = {
              rule = "HostRegexp(`radarr.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker,header-basic@file";
            };
          };
        };
      };
    };

    volumes = {
      radarr = {};
    };

    networks = {
      radarr = {};
    };
  };
}
