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
      image = "lscr.io/linuxserver/prowlarr:2.3.0@sha256:5339e9050cfcc0cb5331e9c98610ed9d4ce70ef481a5461ea664a13dda3f1eb0";
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
