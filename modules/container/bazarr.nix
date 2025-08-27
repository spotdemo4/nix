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
      image = "lscr.io/linuxserver/bazarr:1.5.2@sha256:f9cb78eaec1d77017f5c3e5b7aa07106fe4433a77fd902d01e91213f7c991499";
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
