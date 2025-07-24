{config, ...}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.portainer = {
      containerConfig = {
        image = "docker.io/portainer/portainer-ce:2.32.0@sha256:14c4697739979d67d097b9ff351f3bde1ee2b9511197cd55cb43dc1d41ad72c2";
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
