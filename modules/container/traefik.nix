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

      file.directory = "/conf";
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

  githubSecret = mkSecret "oauth2-github" config.age.secrets."oauth2-github".path;
  cloudflareSecret = mkSecret "cloudflare-dns" config.age.secrets."cloudflare-dns".path;
in {
  age.secrets."auth-basic-traefik".file = self + /secrets/auth-basic-traefik.age;
  age.secrets."oauth2-github".file = self + /secrets/oauth2-github.age;
  age.secrets."cloudflare-dns".file = self + /secrets/cloudflare-dns.age;
  system.activationScripts = {
    "${githubSecret.ref}" = githubSecret.script;
    "${cloudflareSecret.ref}" = cloudflareSecret.script;
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
                middlewares = "auth-github";
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
          TFA_HOSTNAME = "auth.trev.*";
          TFA_COOKIEDOMAIN = "trev.*";

          TFA_AUTHPROVIDER = "github";
          TFA_AUTHGITHUB_CLIENTID = "Ov23liIqL0KHpDH7jnpQ";
          TFA_AUTHGITHUB_ALLOWEDUSERS = "spotdemo4";
          TFA_METRICSSERVERPORT = "2112";
        };
        secrets = [
          "${githubSecret.ref},type=env,target=TFA_AUTHGITHUB_CLIENTSECRET"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.traefik-forward-auth = {
                rule = "HostRegexp(`auth\\.trev\\.(zip|kiwi)`)";
                priority = 500;
              };
              services.traefik-forward-auth.loadbalancer.server = {
                scheme = "http";
                port = 4181;
              };
              middlewares.auth-github.forwardauth = {
                address = "http://traefik-forward-auth:4181";
                trustForwardHeader = true;
                authResponseHeaders = "X-Auth-Request-Access-Token,Authorization";
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
