{...}: {
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
        "traefik.http.routers.portainer.rule" = "Host(`portainer.trev.zip`)";
        "traefik.http.routers.portainer.tls" = "true";
        "traefik.http.routers.portainer.tls.certresolver" = "letsencrypt";
        "traefik.http.services.portainer.loadbalancer.server.scheme" = "http";
        "traefik.http.services.portainer.loadbalancer.server.port" = "9000";
      };
    };
  };
}
