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
      image = "lscr.io/linuxserver/overseerr:latest@sha256:f0bb47460bfbcf7c31dad8b62e2546fb336b4b5209a8404a23e77100da0f25f7";
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
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.overseerr = {
              rule = "HostRegexp(`overseerr.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
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
