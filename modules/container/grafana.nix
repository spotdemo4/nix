{
  self,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  age.secrets."grafana".file = self + /secrets/grafana.age;

  virtualisation.quadlet = {
    containers.grafana.containerConfig = {
      image = "docker.io/grafana/grafana-enterprise:12.1.0@sha256:18c45f066285450e571918af905782cd75298e1929e95bbb8ecb58889d7c5cda";
      pull = "missing";
      user = "root";
      volumes = [
        "${volumes.grafana.ref}:/var/lib/grafana"
        "${config.age.secrets."grafana".path}:/etc/secrets/client"
      ];
      publishPorts = [
        "3000"
      ];
      networks = [
        networks.victoria-metrics.ref
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http.routers.grafana = {
            rule = "HostRegexp(`grafana.trev.(zip|kiwi)`)";
            middlewares = "auth-github@docker";
          };
        };
      };
    };

    volumes = {
      grafana = {};
    };
  };
}
