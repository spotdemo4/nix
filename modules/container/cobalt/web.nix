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
      image = "ghcr.io/spotdemo4/cobalt-web:11.7@sha256:30392487965b2c96f70f04ec5e3ef24a7804eec6ef0c7b9fd7d1e19ed955d1c9";
      pull = "missing";
      environments = {
        WEB_DEFAULT_API = "https://cobalt-api.trev.zip/";
        WEB_HOST = "trev.zip";
      };
      publishPorts = [
        "8787"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.cobalt-web = {
            rule = "Host(`cobalt.trev.zip`)";
            middlewares = "secure@file";
          };
        };
      };
    };
  };
}
