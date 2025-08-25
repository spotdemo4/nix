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
      image = "lscr.io/linuxserver/sabnzbd:4.5.3@sha256:5a3196d71c12603bb0e7ceb83e4b38876510b7ba008d174d7081b69d6dbabd55";
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
