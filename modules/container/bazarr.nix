{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.bazarr.containerConfig = {
      image = "lscr.io/linuxserver/bazarr:1.5.3@sha256:a93c3595410f5c5791a126d7705cd8a29f3ce882338eef304cb8bece3ef2580b";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.bazarr.ref}:/config"
        "/mnt/pool:/pool"
      ];
      publishPorts = [
        "6767"
      ];
      networks = [
        networks."sonarr".ref
        networks."radarr".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.bazarr = {
              rule = "HostRegexp(`bazarr.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      bazarr = {};
    };
  };
}
