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
      image = "docker.io/grafana/grafana-enterprise:12.4.2@sha256:8b6530902b3609dac9f82cabbe5a9778e2ca6eda817c4572d5d5c202102fe76d";
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
