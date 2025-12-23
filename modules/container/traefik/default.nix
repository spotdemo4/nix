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
    publish = true;
    networks = [ networks."traefik".ref ];
    args = [ "--notify-keyspace-events Ksg" ];
  };

  secrets = {
    "cloudflare-dns".file = self + /secrets/cloudflare-dns.age;
    "crowdsec".file = self + /secrets/crowdsec.age;
    "user-admin".file = self + /secrets/user-admin.age;
    "user-trev".file = self + /secrets/user-trev.age;
  };

  virtualisation.quadlet = {
    containers = {
      traefik = {
        containerConfig = {
          image = "docker.io/traefik:v3.6.5@sha256:67622638cd88dbfcfba40159bc652ecf0aea0e032f8a3c7e3134ae7c037b9910";
          pull = "missing";
          secrets = [
            "${secrets."cloudflare-dns".env},target=CF_DNS_API_TOKEN"
            "${secrets."crowdsec".env},target=CROWDSEC"
            "${secrets."user-admin".mount},target=/secrets/user-admin"
            "${secrets."user-trev".mount},target=/secrets/user-trev"
          ];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${configFile}:/etc/traefik/traefik.yml"
            "${providerFile}:/config/provider.yaml"
            "${volumes."acme".ref}:/etc/traefik/acme"
          ];
          publishPorts = [
            "80:80" # http
            "443:443" # https
            "8080:8080" # metrics
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
