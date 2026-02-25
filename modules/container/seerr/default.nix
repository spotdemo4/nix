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
      image = "ghcr.io/seerr-team/seerr:v3.0.1@sha256:1b5fc1ea825631d9d165364472663b817a4c58ef6aa1013f58d82c1570d7c866";
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
