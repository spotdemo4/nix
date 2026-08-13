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
    toContentPath
    ;
  cfg = config.trev.containers.json-exporter;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  network = lib.attrByPath [ cfg.networkName ] { ref = cfg.networkName; } networks;
  configFile = toContentPath cfg.configFile;
in
{
  options.trev.containers.json-exporter = {
    enable = mkEnableOption "the JSON Exporter container";
    image = mkImageOption "quay.io/prometheuscommunity/json-exporter:v0.8.0@sha256:3aad20d41a0b31dfaaf7ab1a091440e92a82a61ef68b76750eac0ad50a983652";

    configFile = mkOption {
      type = types.path;
      default = ./config.yaml;
      description = "JSON Exporter configuration file.";
    };

    networkName = mkOption {
      type = types.str;
      default = "duckmetrics";
      description = "Name of the Quadlet network to attach to JSON Exporter.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.networkName networks;
        message = "trev.containers.json-exporter requires the '${cfg.networkName}' Quadlet network to be defined";
      }
    ];

    virtualisation.quadlet.containers.json-exporter.containerConfig = {
      image = cfg.image;
      pull = "missing";
      volumes = [
        "${configFile}:/json-exporter.yaml"
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
