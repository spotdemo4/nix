{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.sabnzbd.containerConfig = {
      image = "lscr.io/linuxserver/sabnzbd:4.5.3@sha256:b425e5f48e13aabb7c6d9e37579629925ad44f77ae0d841edfd776399457f671";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.sabnzbd.ref}:/config"
        "/mnt/pool/download/sabnzbd:/pool/download/sabnzbd"
      ];
      publishPorts = [
        "8080"
      ];
      networks = [
        networks."sonarr".ref
        networks."radarr".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.sabnzbd = {
              rule = "HostRegexp(`sabnzbd.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      sabnzbd = {};
    };
  };
}
