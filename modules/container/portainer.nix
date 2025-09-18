{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.portainer = {
      containerConfig = {
        image = "docker.io/portainer/portainer-ce:2.34.0@sha256:d61738f5a4670c50395a13a42345a5b9675d96573817ef009a6c7de48ce5a13d";
        pull = "missing";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${volumes.portainer.ref}:/data"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel {
          attrs = {
            traefik = {
              enable = true;
              http = {
                routers.portainer = {
                  rule = "HostRegexp(`portainer.trev.(zip|kiwi)`)";
                  middlewares = "auth-github@docker";
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
      portainer = {};
    };
  };
}
