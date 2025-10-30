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
      image = "lscr.io/linuxserver/sabnzbd:4.5.5@sha256:6e6e7abf7a87436ffccd7df41e64a28df9c530e2be5467339a3f5f0518922b49";
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
