{
  self,
  ...
}:
let
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.moonlight.containerConfig = {
      image = "docker.io/mrcreativ3001/moonlight-web-stream:v2.8@sha256:306353a7de29cff15bbb0738f3c468d9a83c6b9adeb938c2ccb6475450412bf3";
      pull = "missing";
      environments = {
        WEBRTC_NAT_1TO1_HOST = "10.10.10.104";
      };
      publishPorts = [
        "8080"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.moonlight = {
            rule = "Host(`windows.trev.xyz`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };
  };
}
