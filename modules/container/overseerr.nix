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
    containers.overseerr.containerConfig = {
      image = "lscr.io/linuxserver/overseerr:latest@sha256:ad4c6a173bc0f5e1ff9bfa4169fe232fd6556796677d30daa455f6348093a3d5";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.overseerr.ref}:/config"
      ];
      publishPorts = [
        "5055"
      ];
      networks = [
        networks."sonarr".ref
        networks."radarr".ref
        networks."plex".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.overseerr = {
              rule = "Host(`overseerr.trev.xyz`)";
              middlewares = "secure@file";
            };
          };
        };
      };
    };

    volumes = {
      overseerr = { };
    };
  };
}
