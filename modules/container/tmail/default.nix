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
      image = "ghcr.io/linagora/tmail-web:v0.28.19@sha256:b25aac441dfaff274dfad6062c6da69cd98654c90000949d267bb965c9ab7342";
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
