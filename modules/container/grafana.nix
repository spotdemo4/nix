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
      image = "docker.io/grafana/grafana-enterprise:latest";
      pull = "newer";
      autoUpdate = "registry";
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
            rule = "Host(`grafana.trev.zip`)";
            middlewares = "auth-github";
          };
        };
      };
    };

    volumes = {
      grafana = {};
    };
  };
}
