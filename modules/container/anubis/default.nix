{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config) secrets valkey;
  toLabel = import (self + /modules/util/label);

  policy = pkgs.replaceVars ./policy.yaml {
    valkey = valkey."anubis".ref;
  };

  mkAnubis = domain: suffix: port: {
    containerConfig = {
      image = "ghcr.io/techarohq/anubis:latest@sha256:4bdf6ddd1a8dc8bfe7a33d823a1cb72157885ca4fd3ee749654b21cba732e439";
      pull = "missing";
      environments = {
        BIND = ":8080";
        TARGET = " ";
        REDIRECT_DOMAINS = "anubis.${domain},${domain},*.${domain}";
        PUBLIC_URL = "https://anubis.${domain}";
        COOKIE_DOMAIN = "${domain}";
        POLICY_FNAME = "/policy.yaml";
        ED25519_PRIVATE_KEY_HEX_FILE = "/key";
      };
      publishPorts = [
        "${port}:8080"
      ];
      volumes = [
        "${policy}:/policy.yaml:ro"
      ];
      secrets = [
        "${secrets."anubis".mount},target=/key"
      ];
      networks = [
        networks."anubis".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            routers."anubis-${suffix}".rule = "Host(`anubis.${domain}`)";
            middlewares."anubis-${suffix}".forwardauth.address =
              "http://10.10.10.114:${port}/.within.website/x/cmd/anubis/api/check";
          };
        };
      };
    };
  };
in
{
  imports = [
    (self + /modules/container/valkey)
  ];

  valkey."anubis" = {
    networks = [ networks."anubis".ref ];
  };

  secrets."anubis".file = self + /secrets/anubis.age;

  virtualisation.quadlet = {
    containers = {
      "anubis-kiwi" = mkAnubis "trev.kiwi" "kiwi" "8082";
      "anubis-rs" = mkAnubis "trev.rs" "rs" "8083";
      "anubis-xyz" = mkAnubis "trev.xyz" "xyz" "8081";
      "anubis-zip" = mkAnubis "trev.zip" "zip" "8080";
      "anubis-コム" = mkAnubis "trev.コム" "コム" "8084";
    };

    networks = {
      anubis = { };
    };
  };
}
