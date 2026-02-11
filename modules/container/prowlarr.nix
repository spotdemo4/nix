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
    containers.prowlarr.containerConfig = {
      image = "lscr.io/linuxserver/prowlarr:2.3.0@sha256:e74a1e093dcc223d671d4b7061e2b4946f1989a4d3059654ff4e623b731c9134";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.prowlarr.ref}:/config"
      ];
      publishPorts = [
        "9696"
      ];
      networks = [
        networks."sonarr".ref
        networks."radarr".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.prowlarr = {
            rule = "HostRegexp(`prowlarr.trev.(zip|kiwi)`)";
            middlewares = "secure-trev@file";
          };
        };
      };
    };

    volumes = {
      prowlarr = { };
    };
  };
}
