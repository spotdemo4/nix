{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.plex.containerConfig = {
      image = "lscr.io/linuxserver/plex:1.42.2@sha256:b13c1a01150225d88085214dc3deabb41985fa5427766c0126c84780d156b9a9";
      pull = "missing";
      devices = [
        "/dev/dri/card0:/dev/dri/card0"
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
        VERSION = "docker";
      };
      volumes = [
        "${volumes.plex.ref}:/config"
        "/mnt/pool/movies:/movies"
        "/mnt/pool/shows:/shows"
        "/mnt/pool/music:/music"
        "/mnt/fast/plex-data:/transcode"
      ];
      publishPorts = [
        "32400"
      ];
      networks = [
        networks."plex".ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            tcp.routers.plex = {
              rule = "HostSNI(`*`)";
              entryPoints = "plex"; # 32400
            };
            http.routers.plex = {
              rule = "HostRegexp(`plex.trev.(xyz|zip|kiwi)`)";
            };
          };
        };
      };
    };

    volumes = {
      plex = {};
    };

    networks = {
      plex = {};
    };
  };
}
