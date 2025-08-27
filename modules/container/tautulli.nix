{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.tautulli.containerConfig = {
      image = "lscr.io/linuxserver/tautulli:latest@sha256:a87d3d0a9cac97a6c1a623804e2e90929ae4d32f6a122bcf4996dcd2eaaaf2b6";
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
