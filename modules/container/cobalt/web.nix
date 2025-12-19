{
  self,
  ...
}:
let
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet.containers.cobalt-web = {
    containerConfig = {
      image = "ghcr.io/spotdemo4/cobalt-web:11.3@sha256:2e776e4643dccd8f842905bd39e670b3a958f9993af6ace996b6850cfebb8185";
      pull = "missing";
      environments = {
        WEB_DEFAULT_API = "https://cobalt.trev.zip/";
        WEB_HOST = "trev.zip";
      };
      publishPorts = [
        "8787"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.cobalt-web = {
            rule = "Host(`trev.zip`)";
            middlewares = "anubis@file";
          };
        };
      };
    };
  };
}
