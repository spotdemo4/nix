{
  pkgs,
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);

  configFile = (pkgs.formats.yaml {}).generate "prometheus.yml" {
    scrape_configs = [
      {
        job_name = "cadvisor";
        scrape_interval = "15s";
        static_configs = [
          {
            targets = [
              "10.10.10.105:8069" # Gateway
              "10.10.10.107:8069" # Media
              "10.10.10.108:8069" # Build
              "10.10.10.109:8069" # Monitor
              "10.10.10.110:8069" # AI
            ];
          }
        ];
      }
      {
        job_name = "intel-gpu-exporter";
        static_configs = [
          {
            targets = [
              "10.10.10.110:8080" # AI
            ];
          }
        ];
      }
      {
        job_name = "traefik";
        static_configs = [
          {
            targets = [
              "10.10.10.105:8080" # AI
            ];
          }
        ];
      }
    ];
  };
in {
  virtualisation.quadlet = {
    containers.victoria-metrics.containerConfig = {
      image = "docker.io/victoriametrics/victoria-metrics:v1.129.1@sha256:ab12985b467509f37e55835a314f0e6a60e3c82730ab3636666843135dea5033";
      pull = "missing";
      volumes = [
        "${configFile}:/prometheus.yml"
        "${volumes.victoria-metrics.ref}:/victoria-metrics-data"
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
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.victoria-metrics = {
              rule = "HostRegexp(`victoria-metrics.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    networks = {
      victoria-metrics = {};
    };

    volumes = {
      victoria-metrics = {};
    };
  };
}
