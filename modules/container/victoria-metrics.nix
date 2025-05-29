{
  lib,
  pkgs,
  config,
  ...
}: let
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
in {
  virtualisation.quadlet = let
    utils = import ./utils.nix;
    inherit (config.virtualisation.quadlet) networks volumes;
  in {
    containers.victoria-metrics.containerConfig = {
      image = "docker.io/victoriametrics/victoria-metrics:v1.117.1";
      pull = "newer";
      autoUpdate = "registry";
      volumes = [
        "${configFile}:/prometheus.yml"
        "${volumes.victoria-metrics_data.ref}:/victoria-metrics-data"
      ];
      publishPorts = [
        "8428:8428"
      ];
      networks = [
        networks.victoria-metrics.ref
      ];
      exec = [
        "--selfScrapeInterval=5s"
        "-storageDataPath=victoria-metrics-data"
        "-promscrape.config=prometheus.yml"
      ];
      labels = utils.toEnvStrings [] {
        traefik = {
          enable = true;
          http.routers.victoria-metrics = {
            rule = "Host(`victoria-metrics.trev.zip`)";
            entryPoints = "https";
            tls.certresolver = "letsencrypt";
            middlewares = "authelia@docker";
          };
        };
      };
    };

    networks = {
      victoria-metrics = {};
    };

    volumes = {
      victoria-metrics_data = {};
    };
  };
}
