{
  self,
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = import (self + /modules/util/label);
in
{
  secrets."grafana".file = self + /secrets/grafana.age;

  virtualisation.quadlet = {
    containers.grafana.containerConfig = {
      image = "docker.io/grafana/grafana-enterprise:12.4.0@sha256:582fc54fb34a09bf3ecd8ac2196e16705a893582eb460e25db0d37c0b2bb19c4";
      pull = "missing";
      user = "root";
      volumes = [
        "${volumes."grafana".ref}:/var/lib/grafana"
      ];
      publishPorts = [
        "3000"
      ];
      networks = [
        networks."victoria-logs".ref
        networks."victoria-metrics".ref
        networks."victoria-traces".ref
      ];
      secrets = [
        "${config.secrets."grafana".mount},target=/etc/secrets/client"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.grafana = {
              rule = "Host(`grafana.trev.xyz`)";
              middlewares = "secure-admin@file";
            };
          };
        };
      };
    };

    volumes = {
      grafana = { };
    };
  };
}
