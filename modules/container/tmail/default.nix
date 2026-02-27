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
    containers.tmail.containerConfig = {
      image = "ghcr.io/linagora/tmail-web:v0.24.14@sha256:b9e509294c8a299b87c81f154d2848b77b5fb1c65d1232c7b2d5025e96db58d3";
      pull = "missing";
      environments = {
        SERVER_URL = "https://mail.trev.xyz";
      };
      publishPorts = [
        "80"
      ];
      networks = [
        networks."stalwart".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.tmail = {
            rule = "Host(`tmail.trev.xyz`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };
  };
}
