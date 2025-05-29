{
  lib,
  pkgs,
  config,
  ...
}: let
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
in {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) networks volumes;
  in {
    containers = {
      traefik.containerConfig = {
        image = "traefik:latest";
        pull = "newer";
        autoUpdate = "registry";
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${configFile}:/etc/traefik/traefik.yml"
          "${volumes.traefik_acme.ref}:/etc/traefik/acme"
        ];
        publishPorts = [
          "80:80"
          "443:443"
          "8080:8080"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = utils.toEnvStrings [] {
          traefik = {
            enable = true;
            http.routers.api = {
              rule = "Host(`traefik.trev.zip`)";
              entrypoints = "https";
              service = "api@internal";
              tls.certresolver = "letsencrypt";
              middlewares = "authelia@docker";
            };
          };
        };
      };

      traefik-redis.containerConfig = {
        image = "redis:latest";
        pull = "newer";
        autoUpdate = "registry";
        publishPorts = [
          "6379:6379"
        ];
        networks = [
          networks.traefik.ref
        ];
      };
    };

    volumes = {
      traefik_acme = {};
    };

    networks = {
      traefik = {};
    };
  };
}
