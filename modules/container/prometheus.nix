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
        job_name = "prometheus-pve-exporter";
        static_configs = [
          {
            targets = [
              "10.10.10.1"
            ];
          }
        ];
        metrics_path = "/pve";
        params = {
          module = ["default"];
          cluster = ["1"];
          node = ["1"];
        };
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "pve-exporter:9221";
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

  network = utils.mkNetwork "prometheus";
  volume = utils.mkVolume "prometheus_data";
in
  {
    virtualisation.oci-containers.containers = {
      prometheus = {
        image = "prom/prometheus";
        pull = "newer";
        volumes = [
          "${configFile}:/etc/prometheus/prometheus.yml"
          "prometheus_data:/prometheus"
        ];
        ports = [
          "9090:9090"
        ];
        networks = [
          "prometheus"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.radarr.rule" = "Host(`prometheus.trev.zip`)";
          "traefik.http.routers.radarr.entryPoints" = "https";
          "traefik.http.routers.radarr.tls" = "true";
          "traefik.http.routers.radarr.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.radarr.middlewares" = "authelia@docker";
        };
      };
    };
  }
  // lib.recursiveUpdate network volume
