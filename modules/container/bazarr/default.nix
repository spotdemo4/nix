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
    containers.bazarr.containerConfig = {
      image = "lscr.io/linuxserver/bazarr:1.5.5@sha256:c381924dcfd79930e8f3ee75e024671185b810b0f71c984aa8712854c74c1bbb";
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
              middlewares = "secure-admin@file";
            };
          };
        };
      };
    };

    volumes = {
      bazarr = { };
    };
  };
}
