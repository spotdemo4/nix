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
      image = "ghcr.io/linagora/tmail-web:v0.29.3@sha256:71a91750944d38fff7c596b765cb1396393a8840dced885ca39067abcd793d9a";
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
