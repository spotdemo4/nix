{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config) valkey;
  toLabel = import (self + /modules/util/label);

  policy = pkgs.replaceVars ./policy.yaml {
    valkey = valkey."anubis".ref;
  };

  mkAnubis = domain: suffix: port: {
    containerConfig = {
      image = "ghcr.io/techarohq/anubis:latest@sha256:170d30f7de14f6b19e5d7647a1ea8ff58740828a08a6a364e08210df2955639b";
      pull = "missing";
      environments = {
        BIND = ":8080";
        TARGET = " ";
        REDIRECT_DOMAINS = "anubis.${domain},${domain},*.${domain}";
        PUBLIC_URL = "https://${domain}";
        COOKIE_DOMAIN = "${domain}";
        POLICY_FNAME = "/policy.yaml";
      };
      publishPorts = [
        "${port}:8080"
      ];
      volumes = [
        "${policy}:/policy.yaml:ro"
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

  virtualisation.quadlet = {
    containers = {
      "anubis-zip" = mkAnubis "trev.zip" "zip" "8080";
      "anubis-xyz" = mkAnubis "trev.xyz" "xyz" "8081";
    };

    networks = {
      anubis = { };
    };
  };
}
