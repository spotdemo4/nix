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
    containers.seerr.containerConfig = {
      image = "ghcr.io/seerr-team/seerr:v3.1.0@sha256:b35ba0461c4a1033d117ac1e5968fd4cbe777899e4cbfbdeaf3d10a42a0eb7e9";
      pull = "missing";
      environments = {
        LOG_LEVEL = "debug";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes."seerr".ref}:/app/config"
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
            http.routers.seerr = {
              rule = "Host(`overseerr.trev.xyz`) || Host(`seerr.trev.xyz`)";
              middlewares = "secure@file";
            };
          };
        };
      };
    };

    volumes = {
      seerr = { };
    };
  };
}
