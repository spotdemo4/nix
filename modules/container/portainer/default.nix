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
        image = "docker.io/portainer/portainer-ce:2.39.0@sha256:3267f1869e0fa87b843c55f7fd848f9e3001367d053505f4cb8c664e4a997996";
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
