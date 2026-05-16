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
      image = "lscr.io/linuxserver/sabnzbd:5.0.3@sha256:f567ed2e26b964690e93d708d9660db011fcd0a4057f927cae1b6ec23387efd5";
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
