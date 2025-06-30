{config, ...}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.portainer = {
      containerConfig = {
        image = "docker.io/portainer/portainer-ce:2.31.2@sha256:eb7864f3cd4e31e6fe98db53fa5680bfbc627442a87b65770171ad8a822dec0b";
        pull = "missing";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${volumes.portainer.ref}:/data"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
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
