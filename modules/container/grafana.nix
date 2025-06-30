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
      image = "docker.io/grafana/grafana-enterprise:12.0.2@sha256:539b0137768994d8a333e11c510e2da66942a6bdb0ae61216acdd688824fbd46";
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
