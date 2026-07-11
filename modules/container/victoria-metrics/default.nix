{
  lib,
  config,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.victoria-metrics;
  jsonExporter = lib.attrByPath [ "trev" "containers" "json-exporter" ] {
    enable = false;
    networkName = "victoria-metrics";
  } config;
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.victoria-metrics = {
    enable = mkEnableOption "the VictoriaMetrics container";
    image = containerOptions.mkImageOption "docker.io/victoriametrics/victoria-metrics:v1.147.0@sha256:40ea45a6d14b6ad9f2f1fff597309d456ff9885d77d8d1da5fd559b251db9987";

    domain = mkOption {
      type = types.str;
      default = "metrics.trev.xyz";
      description = "Domain routed to VictoriaMetrics.";
    };

    prometheusConfigFile = mkOption {
      type = types.path;
      default = ./prometheus.yaml;
      description = "Prometheus scrape configuration file.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "8428:8428" ];
      description = "Ports to publish from VictoriaMetrics.";
    };

    networkName = mkOption {
      type = types.str;
      default = "victoria-metrics";
      description = "Name of the VictoriaMetrics Quadlet network.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "victoria-metrics";
      description = "Name of the persistent VictoriaMetrics data volume.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.prometheusConfigFile != ./prometheus.yaml || jsonExporter.enable;
        message = "trev.containers.victoria-metrics requires trev.containers.json-exporter.enable = true when using the bundled Prometheus configuration";
      }
      {
        assertion =
          cfg.prometheusConfigFile != ./prometheus.yaml || jsonExporter.networkName == cfg.networkName;
        message = "trev.containers.victoria-metrics and trev.containers.json-exporter must use the same network with the bundled Prometheus configuration";
      }
    ];

    virtualisation.quadlet = {
      containers.victoria-metrics.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/victoria-metrics-data"
          "${cfg.prometheusConfigFile}:/prometheus.yaml"
        ];
        publishPorts = cfg.publishPorts;
        networks = [
          networks.${cfg.networkName}.ref
        ];
        exec = [
          "--selfScrapeInterval=5s"
          "-storageDataPath=victoria-metrics-data"
          "-promscrape.config=prometheus.yaml"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.victoria-metrics = {
              rule = "Host(`${cfg.domain}`)";
              middlewares = "secure-trev@file";
            };
          };
        };
      };

      networks.${cfg.networkName} = { };
      volumes.${cfg.volumeName} = { };
    };
  };
}
