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
      image = "ghcr.io/linagora/tmail-web:v0.29.8@sha256:31aaa0313deb516581250a37a1f2131e142887f9ed439d5341ab2868918d3407";
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
