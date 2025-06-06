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

  githubSecret = mkSecret "oauth2-github" config.age.secrets."oauth2-github".path;
  cookieSecret = mkSecret "oauth2-cookie" config.age.secrets."oauth2-cookie".path;
in {
  age.secrets."oauth2-github".file = self + /secrets/oauth2-github.age;
  age.secrets."oauth2-cookie".file = self + /secrets/oauth2-cookie.age;
  system.activationScripts = {
    "${githubSecret.ref}" = githubSecret.script;
    "${cookieSecret.ref}" = cookieSecret.script;
  };

  virtualisation.quadlet = {
    containers = {
      traefik.containerConfig = {
        image = "docker.io/traefik:latest";
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
        labels = toLabel [] {
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

      oauth-github.containerConfig = {
        image = "quay.io/oauth2-proxy/oauth2-proxy:latest";
        pull = "newer";
        autoUpdate = "registry";
        environments = {
          OAUTH2_PROXY_HTTP_ADDRESS = ":4180";

          # Github provider
          OAUTH2_PROXY_PROVIDER = "github";
          OAUTH2_PROXY_GITHUB_USER = "spotdemo4";
          OAUTH2_PROXY_CLIENT_ID = "Ov23liIqL0KHpDH7jnpQ";
          OAUTH2_PROXY_EMAIL_DOMAINS = "*";

          # Logging
          OUATH2_PROXY_SHOW_DEBUG_ON_ERROR = "true";

          # Cookie storage
          OAUTH2_PROXY_COOKIE_HTTPONLY = "true";
          OAUTH2_PROXY_COOKIE_REFRESH = "1h";
          OAUTH2_PROXY_COOKIE_SECURE = "true";

          # Headers
          OAUTH2_PROXY_SET_AUTHORIZATION_HEADER = "true";
          OAUTH2_PROXY_SET_XAUTHREQUEST = "true";
          OAUTH2_PROXY_PASS_AUTHORIZATION_HEADER = "true";
          OAUTH2_PROXY_PASS_ACCESS_TOKEN = "true";
          OAUTH2_PROXY_PASS_BASIC_AUTH = "true";

          # Skip oauth2-proxy if the request has a JWT already
          OAUTH2_PROXY_SKIP_JWT_BEARER_TOKENS = "true";

          # Do not strip auth headers
          OAUTH2_PROXY_SKIP_AUTH_STRIP_HEADERS = "false";

          # Use the secure code challenge
          OAUTH2_PROXY_CODE_CHALLENGE_METHOD = "S256";

          # Redirects
          OAUTH2_PROXY_REDIRECT_URL = "https://oauth.trev.zip/oauth2/github/callback";
          OAUTH2_PROXY_COOKIE_DOMAINS = ".trev.zip";
          OAUTH2_PROXY_WHITELIST_DOMAINS = ".trev.zip";

          # Proxy
          OAUTH2_PROXY_UPSTREAMS = "static://202";
          OAUTH2_PROXY_REVERSE_PROXY = "true";
          OAUTH2_PROXY_REAL_CLIENT_IP_HEADER = "X-Forwarded-For";
          OAUTH2_PROXY_PREFIX = "/oauth2/github";
        };
        secrets = [
          "${githubSecret.ref},type=env,target=OAUTH2_PROXY_CLIENT_SECRET"
          "${cookieSecret.ref},type=env,target=OAUTH2_PROXY_COOKIE_SECRET"
        ];
        networks = [
          networks.traefik.ref
        ];
        labels = toLabel [] {
          traefik = {
            enable = true;
            http = {
              routers.oauth-github = {
                rule = "HostRegexp(`.+\\.trev\\.zip`) && PathPrefix(`/oauth2/github/`)";
                entryPoints = "https";
                priority = 500;
                tls.certresolver = "letsencrypt";
              };
              services.oauth-github.loadbalancer.server = {
                scheme = "http";
                port = 4180;
              };
              middlewares = {
                oauth-github.forwardauth = {
                  address = "http://oauth-github:4180";
                  trustForwardHeader = true;
                  authResponseHeaders = "X-Auth-Request-Access-Token,Authorization";
                };
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
