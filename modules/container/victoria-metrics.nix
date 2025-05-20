{
  lib,
  pkgs,
  config,
  ...
}: let
  utils = import ./utils.nix {inherit pkgs config;};

  configFile = (pkgs.formats.yaml {}).generate "prometheus.yml" {
    scrape_configs = [
      {
        job_name = "cadvisor";
        scrape_interval = "15s";
        static_configs = [
          {
            targets = [
              "10.10.10.105:8069"
              "10.10.10.107:8069"
              "10.10.10.108:8069"
              "10.10.10.109:8069"
            ];
          }
        ];
      }
      {
        job_name = "intel-gpu-exporter";
        static_configs = [
          {
            targets = [
              "intel-gpu-exporter-card0:8080"
              "intel-gpu-exporter-card1:8080"
            ];
          }
        ];
      }
      {
        job_name = "traefik";
        static_configs = [
          {
            targets = [
              "10.10.10.105:8080"
            ];
          }
        ];
      }
    ];
  };

  network = utils.mkNetwork "victoria-metrics";
  volume = utils.mkVolume "victoria-metrics_data";
in
  {
    virtualisation.oci-containers.containers = {
      prometheus = {
        image = "victoriametrics/victoria-metrics:v1.117.1";
        pull = "newer";
        volumes = [
          "${configFile}:/prometheus.yml"
          "victoria-metrics_data:/victoria-metrics-data"
        ];
        ports = [
          "8428:8428"
        ];
        networks = [
          "victoria-metrics"
        ];
        cmd = "--selfScrapeInterval=5s -storageDataPath=victoria-metrics-data -promscrape.config prometheus.yml";
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.radarr.rule" = "Host(`victoria-metrics.trev.zip`)";
          "traefik.http.routers.radarr.entryPoints" = "https";
          "traefik.http.routers.radarr.tls" = "true";
          "traefik.http.routers.radarr.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.radarr.middlewares" = "authelia@docker";
        };
      };
    };
  }
  // lib.recursiveUpdate network volume
