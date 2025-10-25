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
      image = "docker.io/grafana/grafana-enterprise:12.2.1@sha256:0fa9cbdd2826d3866238a22f12330aa70f263129324509756fe0ee1b570a8e21";
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
