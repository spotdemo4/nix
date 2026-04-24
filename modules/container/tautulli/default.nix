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
      image = "lscr.io/linuxserver/tautulli:latest@sha256:8a5fa2a6c585abc64c4ca5423c4a272257363444ed36882ac84ecb6b455da7f0";
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
