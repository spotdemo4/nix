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
      image = "lscr.io/linuxserver/radarr:5.28.0@sha256:c984533510abe0219a70e80d15bd0d212b7df21baa0913759c4ce6cc9092240b";
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
