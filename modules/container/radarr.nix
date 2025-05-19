{pkgs, ...}: {
  # Create volume for radarr
  system.activationScripts.mkPortainer = ''
    ${pkgs.podman}/bin/podman volume inspect radarr_data || ${pkgs.podman}/bin/podman volume create radarr_data
  '';

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
        "radarr_data:/config"
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
