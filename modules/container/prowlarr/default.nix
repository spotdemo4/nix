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
      image = "lscr.io/linuxserver/prowlarr:2.3.5@sha256:35f48abb3e976fcf077fae756866c582e4a90f8b24810ae4067b3558f7cdbbdf";
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
