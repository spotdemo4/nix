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
        REDIRECT_DOMAINS = "anubis.trev.xyz,trev.xyz,*.trev.xyz,trev.zip,*.trev.zip";
        PUBLIC_URL = "https://anubis.trev.xyz";
        COOKIE_DOMAIN = "trev.xyz";
        SLOG_LEVEL = "DEBUG";
        POLICY_FNAME = "/policy.yaml";
      };
      networks = [
        networks."traefik".ref
      ];
      publishPorts = [
        "8080"
      ];
      volumes = [
        "${./policy.yaml}:/policy.yaml:ro"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.anubis = {
            rule = "Host(`anubis.trev.xyz`)";
          };
        };
      };
    };
  };
}
