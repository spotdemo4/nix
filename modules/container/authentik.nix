{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = (import ./utils/toLabel.nix).toLabel;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  serverSecret = mkSecret "authentik-server" config.age.secrets."authentik-server".path;
  postgresSecret = mkSecret "authentik-postgres" config.age.secrets."authentik-postgres".path;
in {
  age.secrets."authentik-server".file = self + /secrets/authentik-server.age;
  age.secrets."authentik-postgres".file = self + /secrets/authentik-postgres.age;
  system.activationScripts = {
    "${serverSecret.ref}" = serverSecret.script;
    "${postgresSecret.ref}" = postgresSecret.script;
  };

  virtualisation.quadlet = {
    containers = {
      "authentik-postgres".containerConfig = {
        image = "docker.io/library/postgres:16-alpine";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          POSTGRES_DB = "authentik";
          POSTGRES_USER = "authentik";
        };
        secrets = [
          "${postgresSecret.ref},type=env,target=POSTGRES_PASSWORD"
        ];
        volumes = [
          "${volumes.authentik-postgres.ref}:/var/lib/postgresql/data"
        ];
        networks = [
          networks.authentik.ref
        ];
      };

      "authentik-redis".containerConfig = {
        image = "docker.io/library/redis:alpine";
        pull = "newer";
        autoUpdate = "registry";
        volumes = [
          "${volumes.authentik-redis.ref}:/data"
        ];
        networks = [
          networks.authentik.ref
        ];
      };

      "authentik-server".containerConfig = {
        image = "ghcr.io/goauthentik/server:2025.6.0";
        pull = "newer";
        autoUpdate = "registry";
        exec = "server";
        environments = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        secrets = [
          "${serverSecret.ref},type=env,target=AUTHENTIK_SECRET_KEY"
          "${postgresSecret.ref},type=env,target=AUTHENTIK_POSTGRESQL__PASSWORD"
        ];
        volumes = [
          "${volumes.authentik-media.ref}:/media"
          "${volumes.authentik-templates.ref}:/templates"
        ];
        networks = [
          networks.authentik.ref
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.authentik = {
                rule = "Host(`authentik.trev.zip`)";
                entryPoints = "https";
                tls.certresolver = "letsencrypt";
              };
              services.authentik.loadbalancer.server = {
                scheme = "http";
                port = 9000;
              };
              middlewares.authentik.forwardauth = {
                address = "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik";
                trustForwardHeader = true;
                authResponseHeaders = "X-authentik-username,X-authentik-groups,X-authentik-entitlements,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
              };
            };
          };
        };
      };

      "authentik-worker".containerConfig = {
        image = "ghcr.io/goauthentik/server:2025.6.0";
        pull = "newer";
        autoUpdate = "registry";
        exec = "worker";
        user = "root";
        environments = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
        };
        secrets = [
          "${serverSecret.ref},type=env,target=AUTHENTIK_SECRET_KEY"
          "${postgresSecret.ref},type=env,target=AUTHENTIK_POSTGRESQL__PASSWORD"
        ];
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${volumes.authentik-media.ref}:/media"
          "${volumes.authentik-templates.ref}:/templates"
          "${volumes.authentik-certs.ref}:/certs"
        ];
        networks = [
          networks.authentik.ref
        ];
      };
    };

    volumes = {
      authentik-postgres = {};
      authentik-redis = {};
      authentik-media = {};
      authentik-templates = {};
      authentik-certs = {};
    };

    networks = {
      authentik = {};
    };
  };
}
