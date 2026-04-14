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
      image = "ghcr.io/seerr-team/seerr:v3.1.1@sha256:d535391db3b5a22ce02241e6d7a50ca714e75d927e46aa20456b77fa051cbf52";
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
