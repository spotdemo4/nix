{pkgs, ...}: let
  utils = import ./utils.nix;
in {
  inherit (utils.mkVolume "grafana_data");

  virtualisation.oci-containers.containers = {
    grafana = {
      image = "grafana/grafana-enterprise:latest";
      pull = "newer";
      environment = {
        GF_SERVER_ROOT_URL = "https://grafana.trev.zip";
      };
      volumes = [
        "grafana_data:/var/lib/grafana"
      ];
      ports = [
        "3000:3000"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.grafana.rule" = "Host(`grafana.trev.zip`)";
        "traefik.http.routers.grafana.entryPoints" = "https";
        "traefik.http.routers.grafana.tls" = "true";
        "traefik.http.routers.grafana.tls.certresolver" = "letsencrypt";
      };
    };
  };
}
