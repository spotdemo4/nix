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
      image = "lscr.io/linuxserver/prowlarr:2.3.0@sha256:475853535de3de8441b87c1457c30f2e695f4831228b12b6b7274e9da409d874";
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
        attrs = {
          traefik = {
            enable = true;
            http.routers.prowlarr = {
              rule = "HostRegexp(`prowlarr.trev.(zip|kiwi)`)";
              middlewares = "auth-trev@file";
            };
          };
        };
      };
    };

    volumes = {
      prowlarr = { };
    };
  };
}
