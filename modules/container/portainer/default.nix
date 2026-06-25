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
    containers.portainer = {
      containerConfig = {
        image = "docker.io/portainer/portainer-ce:2.43.0@sha256:707366c811956fe077135a6633af67e698529612869711cdb24896c892b28feb";
        pull = "missing";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${volumes.portainer.ref}:/data"
        ];
        networks = [
          networks."traefik".ref
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http = {
                routers.portainer = {
                  rule = "HostRegexp(`portainer.trev.(zip|kiwi)`)";
                  middlewares = "secure-trev@file";
                };
                services.portainer.loadbalancer.server = {
                  scheme = "http";
                  port = 9000;
                };
              };
            };
          };
        };
      };

      unitConfig = {
        After = "podman.socket";
        BindsTo = "podman.socket";
        ReloadPropagatedFrom = "podman.socket";
      };
    };

    volumes = {
      portainer = { };
    };
  };
}
