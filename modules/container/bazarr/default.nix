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
      image = "lscr.io/linuxserver/bazarr:1.5.6@sha256:047222423d6d8556a88581b189175bec57f286f120b52ba29c0390fe6babaa5a";
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
