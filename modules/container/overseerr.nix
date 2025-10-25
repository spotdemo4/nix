{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.overseerr.containerConfig = {
      image = "lscr.io/linuxserver/overseerr:latest@sha256:c5f3c0c246f121b5e4bc8cda2b6e22806f1e1443fc4235c3c050e5b09ae8eda7";
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
      overseerr = {};
    };
  };
}
