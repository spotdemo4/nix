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
    secretType
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
    image = mkImageOption "trev.zip/llc/duckmetrics:3.0.2@sha256:255dd6a0d5d2361aa506c68debf798a23645ef57c371ebae8e63136588e26f79";

    prometheusConfigFile = mkOption {
      type = types.path;
      default = ./prometheus.yaml;
      description = "Prometheus scrape configuration file.";
    };

    quackTokenSecret = mkOption {
      type = secretType;
      default = {
        ref = "duckmetrics-quack-token";
        file = self + /secrets/duckmetrics-quack-token.age;
      };
      description = "DuckMetrics Quack authentication token secret.";
    };

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [
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
      secrets.${cfg.quackTokenSecret.ref} = cfg.quackTokenSecret;

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
        secrets = [
          {
            inherit (cfg.quackTokenSecret) ref;
            type = "env";
            target = "DUCKMETRICS_QUACK_TOKEN";
          }
        ];
        # v3 can't open the v2 database, so it starts a new one. The v2 file
        # stays at /data/duckmetrics.duckdb for rollback or direct querying.
        exec = [
          "--duckdb"
          "/data/duckmetrics-v3.duckdb"
          "--otlp.grpc-endpoint"
          "0.0.0.0:4317"
          "--otlp.http-endpoint"
          "0.0.0.0:4318"
          "--journal-upload.endpoint"
          "0.0.0.0:19532"
          "--health.endpoint"
          "0.0.0.0:13133"
          "--quack"
          "--quack.uri"
          "quack:0.0.0.0:9494"
          "--prometheus.config"
          "/prometheus.yaml"
          "--allow-insecure-non-loopback"
        ]
        ++ cfg.extraArgs;
        stopTimeout = 45;
      };

      networks.${cfg.networkName} = { };
      volumes.${cfg.volumeName} = { };
    };

    systemd.services.duckmetrics.serviceConfig.RestartSec = "5m";
  };
}
