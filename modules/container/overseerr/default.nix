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
      image = "lscr.io/linuxserver/overseerr:latest@sha256:987a6bd200a88501a5fa0cfa0c3179acd83e5b0af986da1537b70f44cfe059b8";
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
