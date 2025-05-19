{pkgs, ...}: let
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
            ];
          }
        ];
      }
    ];
  };

  utils = import ./utils.nix;
in {
  inherit (utils.mkVolume "prometheus_data");

  virtualisation.oci-containers.containers = {
    prometheus = {
      image = "prom/prometheus";
      pull = "newer";
      volumes = [
        "${configFile}:/etc/prometheus/prometheus.yml"
        "prometheus_data:/prometheus"
      ];
    };
  };
}
