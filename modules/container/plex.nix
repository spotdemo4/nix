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
      image = "lscr.io/linuxserver/plex:1.42.1@sha256:3380d8901bf62a9b2246e665d6b8d1f9e03847327b539fb95feef681a8a171ff";
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
