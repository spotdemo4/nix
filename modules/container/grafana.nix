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
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.rule" = "Host(`grafana.trev.zip`)";
        "traefik.http.routers.radarr.entryPoints" = "https";
        "traefik.http.routers.radarr.tls" = "true";
        "traefik.http.routers.radarr.tls.certresolver" = "letsencrypt";
      };
    };
  };
}
