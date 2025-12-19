{
  self,
  ...
}:
let
  toLabel = import (self + /modules/util/label);
  mkAnubis = domain: suffix: port: {
    "anubis-${suffix}".containerConfig = {
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
        "8080:${port}"
      ];
      volumes = [
        "${./policy.yaml}:/policy.yaml:ro"
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
  virtualisation.quadlet.containers =
    mkAnubis "trev.zip" "zip" "8080" // mkAnubis "trev.xyz" "xyz" "8081";
}
