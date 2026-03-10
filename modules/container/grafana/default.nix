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
      image = "docker.io/grafana/grafana-enterprise:12.4.1@sha256:8e8fc4c728843dfc460e7c4c52317eebe71b647b52b4af5fb2f62af7d8831e7d";
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
