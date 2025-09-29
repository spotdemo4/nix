{
  pkgs,
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);

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
        filename = "/conf/secret.yml";
        watch = true;
      };
    };

    entryPoints = {
      http = {
        address = ":80";
        http3 = {};
        http.redirections.entryPoint = {
          to = "https";
          scheme = "https";
        };
      };
      https = {
        address = ":443";
        AsDefault = true;
        http3 = {};
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
            {
              main = "trev.xyz";
              sans = ["*.trev.xyz"];
            }
          ];
        };
      };
      minecraft = {
        address = ":25565";
      };
      plex = {
        address = ":32400";
      };
    };

    certificatesResolvers.letsencrypt.acme = {
      email = "me@trev.xyz";
      storage = "/etc/traefik/acme/acme.json";
      dnsChallenge.provider = "cloudflare";
    };

    tls.options.default.minVersion = "VersionTLS12";
  };
in {
  secrets = {
    "auth-cookie".file = self + /secrets/auth-cookie.age;
    "auth-github".file = self + /secrets/auth-github.age;
    "auth-plex".file = self + /secrets/auth-plex.age;
    "cloudflare-dns".file = self + /secrets/cloudflare-dns.age;
    "traefik".file = self + /secrets/traefik.age;
  };

  virtualisation.quadlet = {
    containers = {
      traefik = {
        containerConfig = {
          image = "docker.io/traefik:v3.5.3@sha256:84eb6c0e67c99fa026bf1bf4b0afd9ad44350d375b4ebc5049c5f70543a729d6";
          pull = "missing";
          secrets = [
            "${secrets."traefik".mount},target=/conf/secret.yml"
            "${secrets."cloudflare-dns".env},target=CF_DNS_API_TOKEN"
          ];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${configFile}:/etc/traefik/traefik.yml"
            "${volumes."traefik_acme".ref}:/etc/traefik/acme"
          ];
          publishPorts = [
            "80:80" # http
            "443:443" # https
            "32400:32400" # plex
            "25565:25565" # minecraft
          ];
          networks = [
            networks."traefik".ref
          ];
          labels = toLabel {
            attrs.traefik = {
              enable = true;
              http.routers.api = {
                rule = "HostRegexp(`traefik.trev.(zip|kiwi)`)";
                service = "api@internal";
                middlewares = "auth-github@docker";
              };
            };
          };
        };

        unitConfig = {
          After = "podman.socket";
          BindsTo = "podman.socket";
          ReloadPropagatedFrom = "podman.socket";
        };
      };

      traefik-redis.containerConfig = {
        image = "docker.io/redis/redis-stack-server:7.4.0-v5@sha256:bf3ee511b24c952341d357039e2d706617fa9f34f633696d0b1fef42df02f375";
        pull = "missing";
        environments = {
          REDIS_ARGS = "--notify-keyspace-events Ksg";
        };
        publishPorts = [
          "6379:6379"
        ];
        networks = [
          networks."traefik".ref
        ];
      };

      traefik-auth-github.containerConfig = {
        image = "ghcr.io/spotdemo4/traefik-forward-auth:edge@sha256:f7c41686cc4a84feb7f32ef4fa20ead85f58a423752ea81fdd107f8b33db2328";
        pull = "missing";
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
          "${secrets."auth-github".env},target=TFA_AUTHGITHUB_CLIENTSECRET"
          "${secrets."auth-cookie".env},target=TFA_TOKENSIGNINGKEY"
        ];
        networks = [
          networks."traefik".ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http = {
              routers.traefik-auth-github = {
                rule = "HostRegexp(`auth-github.trev.(zip|kiwi)`)";
                priority = 500;
              };
              services.traefik-auth-github.loadbalancer.server = {
                scheme = "http";
                port = 4181;
              };
              middlewares.auth-github.forwardauth = {
                address = "http://traefik-auth-github:4181";
                trustForwardHeader = true;
                authResponseHeaders = "X-Forwarded-User,X-Forwarded-Email";
              };
            };
          };
        };
      };

      traefik-auth-plex.containerConfig = {
        image = "ghcr.io/spotdemo4/traefik-forward-auth:edge@sha256:f7c41686cc4a84feb7f32ef4fa20ead85f58a423752ea81fdd107f8b33db2328";
        pull = "missing";
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
          "${secrets."auth-plex".env},target=TFA_AUTHPLEX_TOKEN"
          "${secrets."auth-cookie".env},target=TFA_TOKENSIGNINGKEY"
        ];
        networks = [
          networks."traefik".ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http = {
              routers.traefik-auth-plex = {
                rule = "HostRegexp(`auth-plex.trev.(zip|kiwi)`)";
                priority = 500;
              };
              services.traefik-auth-plex.loadbalancer.server = {
                scheme = "http";
                port = 4181;
              };
              middlewares.auth-plex.forwardauth = {
                address = "http://traefik-auth-plex:4181";
                trustForwardHeader = true;
                authResponseHeaders = "X-Forwarded-User,X-Forwarded-Email";
              };
            };
          };
        };
      };

      traefik-certs-dumper.containerConfig = {
        image = "ghcr.io/kereis/traefik-certs-dumper:1.8.10@sha256:c5bbc45fb631c70ff15f3dd2fde8486902d28e933c40cbbdd7988a4c9d4b84eb";
        pull = "missing";
        user = "1000";
        group = "1000";
        addCapabilities = [
          "CAP_DAC_OVERRIDE"
        ];
        volumes = [
          "${volumes."traefik_acme".ref}:/traefik"
          "/mnt/certs:/output"
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
