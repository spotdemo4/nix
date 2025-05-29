{
  pkgs,
  config,
  ...
}: {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) networks volumes;
  in {
    containers.portainer.containerConfig = {
      image = "portainer/portainer-ce:latest";
      pull = "newer";
      autoUpdate = "registry";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
        "${volumes.portainer_data.ref}:/data"
      ];
      networks = [
        networks.portainer.ref
      ];
      labels = utils.toEnvStrings [] {
        traefik = {
          enable = true;
          http = {
            routers.portainer = {
              rule = "Host(`port.trev.zip`)";
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

    networks = {
      portainer = {};
    };
  };
}
