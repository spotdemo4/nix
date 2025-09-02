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
      image = "lscr.io/linuxserver/plex:1.42.1@sha256:28f18c27b6822328df994154dbf7c0f511032d9f91bbd10881030b706afd8593";
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
