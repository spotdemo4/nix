{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = import (self + /modules/util/label);
in {
  secrets."grafana".file = self + /secrets/grafana.age;

  virtualisation.quadlet = {
    containers.grafana.containerConfig = {
      image = "docker.io/grafana/grafana-enterprise:12.2.0@sha256:54f21c7281241efa917b344439728b8a8b360637833918e8164dc843aa47633f";
      pull = "missing";
      user = "root";
      volumes = [
        "${volumes.grafana.ref}:/var/lib/grafana"
      ];
      publishPorts = [
        "3000"
      ];
      networks = [
        networks.victoria-metrics.ref
      ];
      secrets = [
        "${config.secrets."grafana".mount},target=/etc/secrets/client"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.grafana = {
              rule = "HostRegexp(`grafana.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      grafana = {};
    };
  };
}
