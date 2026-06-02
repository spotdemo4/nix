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
      image = "ghcr.io/seerr-team/seerr:v3.3.0@sha256:c92d2dc117f62185e7bcb88cd56efd374ea79210eaf433275449e8d5988eb5a8";
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
