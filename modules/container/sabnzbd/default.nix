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
    containers.sabnzbd.containerConfig = {
      image = "lscr.io/linuxserver/sabnzbd:4.5.5@sha256:e4573bab787c2ba9a9e6bbf5535da0bd9d4de8e247ac7fad6428319fadd2331d";
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
              middlewares = "secure-trev@file";
            };
          };
        };
      };
    };

    volumes = {
      sabnzbd = { };
    };
  };
}
