{config, ...}: {
  virtualisation.quadlet = let
    toLabel = (import ./utils/toLabel.nix).toLabel;
    inherit (config.virtualisation.quadlet) networks volumes;
  in {
    containers.portainer.containerConfig = {
      image = "docker.io/portainer/portainer-ce:latest";
      pull = "newer";
      autoUpdate = "registry";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
        "${volumes.portainer_data.ref}:/data"
      ];
      networks = [
        networks.traefik.ref
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http = {
            routers.portainer = {
              rule = "Host(`portainer.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
            };
            services.portainer.loadbalancer.server = {
              scheme = "http";
              port = 9000;
            };
          };
        };
      };
    };

    volumes = {
      portainer_data = {};
    };
  };
}
