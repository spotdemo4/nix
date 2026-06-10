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
      image = "lscr.io/linuxserver/radarr:6.2.1@sha256:4c490ccd44d31feb49dc4cc542f2148a420fc1ae0c1ba94e59b39ba4bf112716";
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
        attrs.traefik = {
          enable = true;
          http.routers.radarr = {
            rule = "HostRegexp(`radarr.trev.(zip|kiwi)`)";
            middlewares = "secure-admin@file";
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
