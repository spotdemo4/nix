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
    containers.tautulli.containerConfig = {
      image = "lscr.io/linuxserver/tautulli:latest@sha256:24594d6aed5f862f941349a6fa0d09d22d7a8386789aef954d3737c6b4dbb8c7";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.tautulli.ref}:/config"
      ];
      publishPorts = [
        "8181"
      ];
      networks = [
        networks."plex".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.tautulli = {
              rule = "HostRegexp(`tautulli.trev.(zip|kiwi)`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };
    };

    volumes = {
      tautulli = { };
    };
  };
}
