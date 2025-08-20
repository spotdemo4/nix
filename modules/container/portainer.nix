{config, ...}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.portainer = {
      containerConfig = {
        image = "docker.io/portainer/portainer-ce:2.33.0@sha256:d5b9eba8d4d2f4e952aee6a6fb154e618857a976f734bfcec5a5603b03f45acd";
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
