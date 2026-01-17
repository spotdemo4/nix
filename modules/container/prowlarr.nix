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
      image = "lscr.io/linuxserver/prowlarr:2.3.0@sha256:d3e9307b320b6772749a2cf8fc2712e9e824c4930b034680ad4d08a9e2f25884";
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
