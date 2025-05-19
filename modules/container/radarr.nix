{pkgs, ...}: {
  virtualisation.oci-containers.containers = {
    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      pull = "newer";
      environment = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "/mnt/pool/movies:/movies"
      ];
      ports = [
        "7878:7878"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.portainer.rule" = "Host(`radarr.trev.zip`)";
        "traefik.http.routers.portainer.tls" = "true";
        "traefik.http.routers.portainer.tls.certresolver" = "letsencrypt";
        "traefik.http.services.portainer.loadbalancer.server.scheme" = "http";
        "traefik.http.services.portainer.loadbalancer.server.port" = "7878";
      };
    };
  };
}
