{
  pkgs,
  config,
  ...
}: let
  utils = import ./utils.nix {inherit pkgs config;};

  configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
    log.level = "DEBUG";
    api.insecure = true;
    metrics.prometheus = true;

    providers = {
      docker = {
        exposedByDefault = false;
        endpoint = "unix:///var/run/docker.sock";
        watch = true;
      };

      redis.endpoints = "traefik-redis:6379";
    };

    entryPoints = {
      http.address = ":80";
      https.address = ":443";
    };

    certificatesResolvers.letsencrypt.acme = {
      email = "me@trev.xyz";
      storage = "/etc/traefik/acme/acme.json";
      httpChallenge.entrypoint = "http";
    };
  };

  network = utils.mkNetwork "traefik";
  volume = utils.mkVolume "traefik_acme";
in
  {
    virtualisation.oci-containers.containers = {
      traefik = {
        image = "traefik:latest";
        pull = "newer";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${configFile}:/etc/traefik/traefik.yml"
          "traefik_acme:/etc/traefik/acme"
        ];
        ports = [
          "80:80"
          "443:443"
          "8080:8080"
        ];
        networks = [
          "traefik"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.api.rule" = "Host(`traefik.trev.zip`)";
          "traefik.http.routers.api.entrypoints" = "https";
          "traefik.http.routers.api.service" = "api@internal";
          "traefik.http.routers.api.tls" = "true";
          "traefik.http.routers.api.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.api.middlewares" = "authelia@docker";
        };
      };

      traefik-redis = {
        image = "redis:latest";
        pull = "newer";
        ports = [
          "6379:6379"
        ];
        networks = [
          "traefik"
        ];
      };
    };
  }
  // network // volume
