{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.anubis.containerConfig = {
      image = "ghcr.io/techarohq/anubis:latest@sha256:170d30f7de14f6b19e5d7647a1ea8ff58740828a08a6a364e08210df2955639b";
      pull = "missing";
      environments = {
        BIND = ":8080";
        TARGET = " ";
        REDIRECT_DOMAINS = "overseerr.trev.xyz";
        PUBLIC_URL = "https://anubis.trev.xyz";
        COOKIE_DOMAIN = "trev.xyz";
        POLICY_FNAME = "/policy.yaml";
      };
      networks = [
        networks."traefik".ref
      ];
      volumes = [
        "${./policy.yaml}:/policy.yaml"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            services.anubis.loadbalancer.server.port = 8080;
            routers.anubis = {
              rule = "Host(`anubis.trev.xyz`)";
              service = "anubis";
            };
            middlewares.anubis.forwardauth.address = "http://anubis:8080/.within.website/x/cmd/anubis/api/check";
          };
        };
      };
    };
  };
}
