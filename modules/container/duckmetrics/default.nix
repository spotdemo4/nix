{
  self,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    toContentPath
    ;
  inherit (config.virtualisation.quadlet)
    networks
    volumes
    ;
  cfg = config.trev.containers.duckmetrics;
  jsonExporter = lib.attrByPath [ "trev" "containers" "json-exporter" ] {
    enable = false;
    networkName = "duckmetrics";
  } config;
  prometheusConfigFile = toContentPath cfg.prometheusConfigFile;
in
{
  options.trev.containers.duckmetrics = {
    enable = mkEnableOption "the DuckMetrics container";
    image = mkImageOption "trev.zip/llc/duckmetrics:2.1.0@sha256:9c0fba194712869d8fb1c32c92501334859f09d3c44f486f5965fe569a39ec75";

    domain = mkOption {
      type = types.str;
      default = "metrics.trev.xyz";
      description = "Domain routed to the DuckMetrics dashboard.";
    };

    prometheusConfigFile = mkOption {
      type = types.path;
      default = ./prometheus.yaml;
      description = "Prometheus scrape configuration file.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [
        "8080:8080"
        "4317:4317"
        "4318:4318"
      ];
      description = "Ports to publish from DuckMetrics.";
    };

    networkName = mkOption {
      type = types.str;
      default = "duckmetrics";
      description = "Name of the DuckMetrics Quadlet network.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "duckmetrics";
      description = "Name of the persistent DuckMetrics data volume.";
    };

    dashboardRefresh = mkOption {
      type = types.str;
      default = "5s";
      description = "DuckMetrics dashboard browser refresh interval.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional arguments passed to DuckMetrics.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.prometheusConfigFile != ./prometheus.yaml || jsonExporter.enable;
        message = "trev.containers.duckmetrics requires trev.containers.json-exporter.enable = true when using the bundled Prometheus configuration";
      }
      {
        assertion =
          cfg.prometheusConfigFile != ./prometheus.yaml || jsonExporter.networkName == cfg.networkName;
        message = "trev.containers.duckmetrics and trev.containers.json-exporter must use the same network with the bundled Prometheus configuration";
      }
    ];

    virtualisation.quadlet = {
      containers.duckmetrics.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "65532";
        group = "65532";
        environments.HOME = "/data";
        workdir = "/data";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/data:U"
          "${prometheusConfigFile}:/prometheus.yaml:ro"
        ];
        publishPorts = cfg.publishPorts;
        networks = [
          networks.${cfg.networkName}.ref
        ];
        exec = [
          "--duckdb"
          "/data/duckmetrics.duckdb"
          "--otlp.grpc-endpoint"
          "0.0.0.0:4317"
          "--otlp.http-endpoint"
          "0.0.0.0:4318"
          "--health.endpoint"
          "0.0.0.0:13133"
          "--dashboard"
          "--dashboard.listen"
          "0.0.0.0:8080"
          "--dashboard.refresh"
          cfg.dashboardRefresh
          "--prometheus.config"
          "/prometheus.yaml"
          "--allow-insecure-non-loopback"
        ]
        ++ cfg.extraArgs;
        stopTimeout = 45;
        labels = {
          traefik = {
            enable = true;
            http = {
              middlewares.duckmetrics-dashboard.headers.customrequestheaders.Host = "0.0.0.0:8080";
              services.duckmetrics.loadbalancer.server.port = 8080;
              routers.duckmetrics = {
                rule = "Host(`${cfg.domain}`)";
                service = "duckmetrics";
                middlewares = "secure-trev@file,duckmetrics-dashboard@redis";
              };
            };
          };
        };
      };

      networks.${cfg.networkName} = { };
      volumes.${cfg.volumeName} = { };
    };
  };
}
