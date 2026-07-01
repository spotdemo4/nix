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
    containers.syncthing.containerConfig = {
      image = "docker.io/syncthing/syncthing:2.1.1@sha256:775c4aac486263ca8653055bba7d3061799281974b706695e17bc798da3f4e92";
      pull = "missing";
      hostname = "syncthing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        STGUIADDRESS = "0.0.0.0:8384";
      };
      volumes = [
        "${volumes.syncthing.ref}:/var/syncthing"
      ];
      publishPorts = [
        "8384:8384"
        "22000:22000/tcp"
        "22000:22000/udp"
      ];
      networks = [
        networks."syncthing".ref
      ];
      healthCmd = "curl -fkLsS -m 2 127.0.0.1:8384/rest/noauth/health | grep -q OK || exit 1";
      healthInterval = "1m";
      healthTimeout = "10s";
      healthRetries = 3;
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            routers.syncthing = {
              rule = "Host(`syncthing.trev.zip`)";
              middlewares = "secure-trev@file";
            };
            services.syncthing.loadbalancer.server.port = 8384;
          };
          tcp = {
            routers.syncthing = {
              rule = "HostSNI(`*`)";
              entryPoints = "syncthing-tcp";
              service = "syncthing";
            };
            services.syncthing.loadbalancer.server.port = 22000;
          };
          udp = {
            routers.syncthing = {
              entryPoints = "syncthing-udp";
              service = "syncthing";
            };
            services.syncthing.loadbalancer.server.port = 22000;
          };
        };
      };
    };

    volumes = {
      syncthing = { };
    };

    networks = {
      syncthing = { };
    };
  };
}
