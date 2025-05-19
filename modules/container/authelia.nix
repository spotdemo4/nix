{pkgs, ...}: {
  # Create volume for authelia
  system.activationScripts.mkAuthelia = ''
    ${pkgs.podman}/bin/podman volume inspect authelia_data || ${pkgs.podman}/bin/podman volume create authelia_data
  '';

  virtualisation.oci-containers.containers = {
    authelia = {
      image = "authelia/authelia:latest";
      pull = "newer";
      volumes = [
        "authelia_data:/config"
      ];
      networks = [
        "traefik"
      ];
      environment = {
        TZ = "America/Detroit";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.authelia.rule" = "Host(`auth.trev.zip`)";
        "traefik.http.routers.authelia.entryPoints" = "https";
        "traefik.http.routers.authelia.tls" = "true";
        "traefik.http.routers.authelia.tls.certresolver" = "letsencrypt";
        "traefik.http.middlewares.authelia.forwardAuth.address" = "http://authelia:9091/api/authz/forward-auth";
        "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader" = "true";
        "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders" = "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
      };
    };
  };
}
