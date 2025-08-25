{self, ...}: let
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet.containers.context7.containerConfig = {
    image = "docker.io/mcp/context7:latest@sha256:1174e6a29634a83b2be93ac1fefabf63265f498c02c72201fe3464e687dd8836";
    pull = "missing";
    publishPorts = [
      "8080"
    ];
    labels = toLabel {
      attrs = {
        traefik = {
          enable = true;
          http.routers.context7 = {
            rule = "HostRegexp(`context7.trev.(zip|kiwi)`)";
          };
        };
      };
    };
  };
}
