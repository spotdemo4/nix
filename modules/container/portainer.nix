{pkgs, ...}: let
  utils = import ./utils.nix;
in {
  inherit (utils.mkVolume "portainer_data");

  virtualisation.oci-containers.containers = {
    portainer = {
      image = "portainer/portainer-ce:latest";
      pull = "newer";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
      networks = [
        "traefik"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.portainer.rule" = "Host(`port.trev.zip`)";
        "traefik.http.routers.portainer.entryPoints" = "https";
        "traefik.http.routers.portainer.tls" = "true";
        "traefik.http.routers.portainer.tls.certresolver" = "letsencrypt";
        "traefik.http.services.portainer.loadbalancer.server.scheme" = "http";
        "traefik.http.services.portainer.loadbalancer.server.port" = "9000";
      };
    };
  };
}
