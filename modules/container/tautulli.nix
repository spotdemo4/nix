{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.tautulli.containerConfig = {
      image = "lscr.io/linuxserver/tautulli:latest@sha256:173e2a76d7e83d31d0dc002e569a1a476cf6d474a65a6b1acc7dbceb41183eb2";
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
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      tautulli = {};
    };
  };
}
