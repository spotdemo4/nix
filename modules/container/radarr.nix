{
  pkgs,
  config,
  ...
}: let
  utils = import ./utils.nix {inherit pkgs config;};

  volume = utils.mkVolume "radarr_data";
in
  {
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
          "traefik.http.routers.radarr.rule" = "Host(`radarr.trev.zip`)";
          "traefik.http.routers.radarr.entryPoints" = "https";
          "traefik.http.routers.radarr.tls" = "true";
          "traefik.http.routers.radarr.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.radarr.middlewares" = "authelia@docker";
          "traefik.http.services.radarr.loadbalancer.server.scheme" = "http";
          "traefik.http.services.radarr.loadbalancer.server.port" = "7878";
        };
      };
    };
  }
  // volume
