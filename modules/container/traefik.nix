{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
  mkSecret = (import ./utils/mkSecret.nix {inherit pkgs config;}).mkSecret;

  configFile = (pkgs.formats.yaml {}).generate "config.yaml" {
    log.level = "WARN";
    api.insecure = true;
    metrics.prometheus = true;

    providers = {
      docker = {
        exposedByDefault = false;
        endpoint = "unix:///var/run/docker.sock";
        watch = true;
      };

      redis.endpoints = "traefik-redis:6379";

      file = {
        filename = "/conf/auth.yml";
        watch = true;
      };
    };

    entryPoints = {
      http = {
        address = ":80";
        http.redirections.entryPoint = {
          to = "https";
          scheme = "https";
        };
      };
      https = {
        address = ":443";
        AsDefault = true;
        http.tls = {
          certResolver = "letsencrypt";
          domains = [
            {
              main = "trev.zip";
              sans = ["*.trev.zip"];
            }
            {
              main = "trev.kiwi";
              sans = ["*.trev.kiwi"];
            }
          ];
        };
      };
    };

    certificatesResolvers.letsencrypt.acme = {
      email = "me@trev.xyz";
      storage = "/etc/traefik/acme/acme.json";
      dnsChallenge.provider = "cloudflare";
    };
  };

  cloudflareSecret = mkSecret "cloudflare-dns" config.age.secrets."cloudflare-dns".path;
  githubSecret = mkSecret "auth-github" config.age.secrets."auth-github".path;
  plexSecret = mkSecret "auth-plex" config.age.secrets."auth-plex".path;
  cookieSecret = mkSecret "auth-cookie" config.age.secrets."auth-cookie".path;
in {
  age.secrets."auth-basic-traefik".file = self + /secrets/auth-basic-traefik.age;
  age.secrets."${cloudflareSecret.ref}".file = self + /secrets/cloudflare-dns.age;
  age.secrets."${githubSecret.ref}".file = self + /secrets/auth-github.age;
  age.secrets."${plexSecret.ref}".file = self + /secrets/auth-plex.age;
  age.secrets."${cookieSecret.ref}".file = self + /secrets/auth-cookie.age;

  system.activationScripts = {
    "${cloudflareSecret.ref}" = cloudflareSecret.script;
    "${githubSecret.ref}" = githubSecret.script;
    "${plexSecret.ref}" = plexSecret.script;
    "${cookieSecret.ref}" = cookieSecret.script;
  };

  virtualisation.quadlet = {
    containers = {
      traefik.containerConfig = {
        image = "docker.io/traefik:latest";
        pull = "newer";
        autoUpdate = "registry";
        secrets = [
          "${cloudflareSecret.ref},type=env,target=CF_DNS_API_TOKEN"
        ];
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
          "${configFile}:/etc/traefik/traefik.yml"
          "${volumes.traefik_acme.ref}:/etc/traefik/acme"
          "${config.age.secrets."auth-basic-traefik".path}:/conf/auth.yml"
        ];
        publishPorts = [
          "80:80"
          "443:443"
          "8080:8080"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.api = {
                rule = "Host(`traefik.trev.zip`)";
                service = "api@internal";
                middlewares = "auth-github@docker";
              };
            };
          };
        };
      };

      traefik-redis.containerConfig = {
        image = "docker.io/redis/redis-stack-server:latest";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          REDIS_ARGS = "--notify-keyspace-events Ksg";
        };
        publishPorts = [
          "6379:6379"
        ];
        networks = [
          networks.traefik.ref
        ];
      };

      traefik-forward-auth.containerConfig = {
        image = "ghcr.io/spotdemo4/traefik-forward-auth:edge";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          TFA_HOSTNAME = "auth-github.trev.*";
          TFA_COOKIEDOMAIN = "trev.*";
          TFA_COOKIENAME = "auth_github";
          TFA_METRICSSERVERPORT = "2112";

          TFA_AUTHPROVIDER = "github";
          TFA_AUTHGITHUB_CLIENTID = "Iv23liIkJQVqxVXVwKIn";
          TFA_AUTHGITHUB_ALLOWEDUSERS = "spotdemo4";
        };
        secrets = [
          "${githubSecret.ref},type=env,target=TFA_AUTHGITHUB_CLIENTSECRET"
          "${cookieSecret.ref},type=env,target=TFA_TOKENSIGNINGKEY"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.traefik-forward-auth = {
                rule = "HostRegexp(`auth-github.trev.(zip|kiwi)`)";
                priority = 500;
              };
              services.traefik-forward-auth.loadbalancer.server = {
                scheme = "http";
                port = 4181;
              };
              middlewares.auth-github.forwardauth = {
                address = "http://traefik-forward-auth:4181";
                trustForwardHeader = true;
                authResponseHeaders = "X-Forwarded-User";
              };
            };
          };
        };
      };

      traefik-forward-auth-plex.containerConfig = {
        image = "ghcr.io/spotdemo4/traefik-forward-auth:edge";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          TFA_HOSTNAME = "auth-plex.trev.*";
          TFA_COOKIEDOMAIN = "trev.*";
          TFA_COOKIENAME = "auth_plex";
          TFA_METRICSSERVERPORT = "2112";

          TFA_AUTHPROVIDER = "plex";
          TFA_AUTHPLEX_CLIENTID = "Iv23liIkJQVqxVXVwKIn";
          TFA_AUTHPLEX_CLIENTNAME = "trev llc inc";
          TFA_AUTHPLEX_ALLOWFRIENDS = "true";
          TFA_AUTHPLEX_ALLOWEDUSERS = "spotdemo4";
        };
        secrets = [
          "${plexSecret.ref},type=env,target=TFA_AUTHPLEX_TOKEN"
          "${cookieSecret.ref},type=env,target=TFA_TOKENSIGNINGKEY"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.traefik-forward-auth-plex = {
                rule = "HostRegexp(`auth-plex.trev.(zip|kiwi)`)";
                priority = 500;
              };
              services.traefik-forward-auth-plex.loadbalancer.server = {
                scheme = "http";
                port = 4181;
              };
              middlewares.auth-plex.forwardauth = {
                address = "http://traefik-forward-auth-plex:4181";
                trustForwardHeader = true;
                authResponseHeaders = "X-Forwarded-User";
              };
            };
          };
        };
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
