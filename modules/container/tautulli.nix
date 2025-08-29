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
      image = "lscr.io/linuxserver/tautulli:latest@sha256:63a8298420139c27aede66e61a1b2f3c4ac56486f2a06ab4776ec47dfdcf312a";
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
        networks."tautulli".ref
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

    networks = {
      tautulli = {};
    };
  };
}
