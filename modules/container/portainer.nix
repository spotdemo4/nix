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
        image = "docker.io/portainer/portainer-ce:2.37.0@sha256:b48a491b8d2838c7ee98da6e00e32a04d0347a26466f48b20fb11e484e28f32a";
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
                  middlewares = "auth-trev@file";
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
