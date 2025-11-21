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
      image = "lscr.io/linuxserver/overseerr:latest@sha256:19fe26c92c48136136478790725d680cedfae0bf9cb0f25c6a44ab3008ad6e6a";
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
              rule = "HostRegexp(`overseerr.trev.(xyz|zip|kiwi)`)";
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
