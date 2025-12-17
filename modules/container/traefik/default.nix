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
    "user-admin".file = self + /secrets/user-admin.age;
    "user-trev".file = self + /secrets/user-trev.age;
  };

  virtualisation.quadlet = {
    containers = {
      traefik = {
        containerConfig = {
          image = "docker.io/traefik:v3.6.5@sha256:2979bff651c98e70345dd886186a7a15ee3ce18b636af208d4ccbf2d56dbdddd";
          pull = "missing";
          secrets = [
            "${secrets."cloudflare-dns".env},target=CF_DNS_API_TOKEN"
            "${secrets."user-admin".mount},target=/secrets/user-admin"
            "${secrets."user-trev".mount},target=/secrets/user-trev"
          ];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${configFile}:/etc/traefik/traefik.yml"
            "${providerFile}:/config/provider.yaml"
            "${volumes."traefik_acme".ref}:/etc/traefik/acme"
          ];
          publishPorts = [
            "80:80" # http
            "443:443" # https
            "32400:32400" # plex
            "25565:25565" # minecraft
            "18080:18080" # monero p2p
            "18084:18084" # monero zmq
            "37889:37889" # p2pool p2p
            "3333:3333" # p2pool stratum
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
              };
            };
          };
        };

        unitConfig = {
          After = [
            "podman.socket"
            valkey."traefik".ref
          ];
          BindsTo = [
            "podman.socket"
            valkey."traefik".ref
          ];
          ReloadPropagatedFrom = "podman.socket";
        };
      };
    };

    volumes = {
      traefik_acme = { };
    };

    networks = {
      traefik = { };
    };
  };
}
