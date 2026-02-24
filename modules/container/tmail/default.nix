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
      image = "ghcr.io/linagora/tmail-web:v0.24.12@sha256:56a24411e8234d50f820f4b0079c5712399aaa863a61972d6df19f54444de77a";
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
