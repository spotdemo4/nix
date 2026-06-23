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
    containers.plex.containerConfig = {
      image = "lscr.io/linuxserver/plex:1.43.2@sha256:f79738b25b19d8e11658e3f2233067732023a1ab2ead8be610d75c55e425ecb8";
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
      plex = { };
    };

    networks = {
      plex = { };
    };
  };
}
