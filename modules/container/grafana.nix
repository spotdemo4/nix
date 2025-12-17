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
      image = "docker.io/grafana/grafana-enterprise:12.3.0@sha256:96a793a92c9a77cf543d6e5c55100cd296ed9e22487dc3d069331364c456247b";
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
