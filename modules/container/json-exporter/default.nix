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
    mkImageOption
    ;
  cfg = config.trev.containers.json-exporter;
  victoriaMetrics = lib.attrByPath [ "trev" "containers" "victoria-metrics" ] {
    enable = false;
    networkName = "victoria-metrics";
  } config;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  network = lib.attrByPath [ cfg.networkName ] { ref = cfg.networkName; } networks;
in
{
  options.trev.containers.json-exporter = {
    enable = mkEnableOption "the JSON Exporter container";
    image = mkImageOption "quay.io/prometheuscommunity/json-exporter:v0.7.0@sha256:3a777171d39ad435cb39519e84e0a8b5c63c7e716cc06011f8140cfaabfc1baf";

    configFile = mkOption {
      type = types.path;
      default = ../victoria-metrics/json-exporter.yaml;
      description = "JSON Exporter configuration file.";
    };

    networkName = mkOption {
      type = types.str;
      default = "victoria-metrics";
      description = "Name of the Quadlet network to attach to JSON Exporter.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.networkName != victoriaMetrics.networkName || victoriaMetrics.enable;
        message = "trev.containers.json-exporter requires trev.containers.victoria-metrics.enable = true when using its network";
      }
      {
        assertion = builtins.hasAttr cfg.networkName networks;
        message = "trev.containers.json-exporter requires the '${cfg.networkName}' Quadlet network to be defined";
      }
    ];

    virtualisation.quadlet.containers.json-exporter.containerConfig = {
      image = cfg.image;
      pull = "missing";
      volumes = [
        "${cfg.configFile}:/json-exporter.yaml"
      ];
      networks = [
        network.ref
      ];
      exec = [
        "--config.file=/json-exporter.yaml"
      ];
    };
  };
}
