{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) valkey secrets;
  toLabel = import (self + /modules/util/label);

  configFile = pkgs.replaceVars ./config.yaml {
    acme = "/etc/traefik/acme";
    file = "/config/provider.yaml";
    redis = valkey."traefik".ref;
  };

  providerFile = pkgs.replaceVars ./provider.yaml {
    user-admin = "/secrets/user-admin";
    user-trev = "/secrets/user-trev";
  };
in
{
  imports = [
    (self + /modules/container/valkey)
    ./certs-dumper.nix
  ];

  valkey."traefik" = {
    publishPorts = [ "10.10.10.105:6379:6379" ];
    networks = [ networks."traefik".ref ];
    args = [ "--notify-keyspace-events Ksg" ];
  };

  secrets = {
    "cloudflare-dns".file = self + /secrets/cloudflare-dns.age;
    "crowdsec".file = self + /secrets/crowdsec.age;
    "cloudflare-turnstile-site-key".file = self + /secrets/cloudflare-turnstile-site-key.age;
    "cloudflare-turnstile-secret-key".file = self + /secrets/cloudflare-turnstile-secret-key.age;
    "user-admin".file = self + /secrets/user-admin.age;
    "user-trev".file = self + /secrets/user-trev.age;
  };

  virtualisation.quadlet = {
    containers = {
      traefik = {
        containerConfig = {
          image = "docker.io/traefik:v3.7.6@sha256:21a3d83696379bac6434bb32e1dde0aff0e84ef2abd053ed3db87d3f45e749b2";
          pull = "missing";
          secrets = [
            "${secrets."cloudflare-dns".env},target=CF_DNS_API_TOKEN"
            "${secrets."crowdsec".mount},target=/secrets/crowdsec/lapi_key"
            "${secrets."cloudflare-turnstile-site-key".mount},target=/secrets/turnstile/site_key"
            "${secrets."cloudflare-turnstile-secret-key".mount},target=/secrets/turnstile/secret_key"
            "${secrets."user-admin".mount},target=/secrets/user-admin"
            "${secrets."user-trev".mount},target=/secrets/user-trev"
          ];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${configFile}:/etc/traefik/traefik.yml"
            "${providerFile}:/config/provider.yaml"
            "${volumes."acme".ref}:/etc/traefik/acme"
            "${./captcha.html}:/captcha.html"
          ];
          publishPorts = [
            "80:80" # http
            "443:443" # https
            "873:873" # rsyncd
            "874:874" # rsyncd-tls
            "8080:8080" # metrics
            "32400:32400" # plex
            "25565:25565" # minecraft
            "22000:22000/tcp" # syncthing-tcp
            "22000:22000/udp" # syncthing-udp
          ];
          networks = [
            networks."traefik".ref
          ];
          labels = toLabel {
            attrs.traefik = {
              enable = true;
              http.routers.api = {
                rule = "Host(`traefik.trev.xyz`)";
                service = "api@internal";
                middlewares = "secure-trev@file";
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
    };

    volumes = {
      acme = { };
    };

    networks = {
      traefik = { };
    };
  };
}
