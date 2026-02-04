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
      image = "lscr.io/linuxserver/bazarr:1.5.5@sha256:d40ee61030a9afafddfdd58d160281b865bfcad7cb66e920116fd6fd40668cbb";
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
