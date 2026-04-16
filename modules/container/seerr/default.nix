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
      image = "ghcr.io/seerr-team/seerr:v3.2.0@sha256:c4cbd5121236ac2f70a843a0b920b68a27976be57917555f1c45b08a1e6b2aad";
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
