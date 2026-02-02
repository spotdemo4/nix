{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:6.0.4@sha256:ba2693dd704b84eb0b404d40b3902bd3e62a1768dc5ee0d89b1f1d7cd51a66eb";
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
              middlewares = "secure-admin@file";
            };
          };
        };
      };
    };

    volumes = {
      radarr = { };
    };

    networks = {
      radarr = { };
    };
  };
}
