{
  config,
  lib,
  self,
  pkgs,
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
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.garage;

  configFile = pkgs.replaceVars ./garage.toml {
    metadata_dir = "/meta";
    data_dir = "/data";
    rpc_secret_file = "/secrets/rpc-secret";
    admin_token_file = "/secrets/admin-token";
    metrics_token_file = "/secrets/metrics-token";
  };
in
{
  options.trev.containers.garage = {
    enable = mkEnableOption "Garage container";
    image = mkImageOption "docker.io/dxflrs/garage:v2.4.1@sha256:9c96caa2612d3411acc5b0e6701fb238dbfba33e533a6d7d3d811a4b12d0d020";

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/garage";
      description = "Host path containing Garage object data.";
    };

    s3Domain = mkOption {
      type = types.str;
      default = "s3.trev.zip";
      description = "Root domain routed to the Garage S3 API.";
    };

    webDomain = mkOption {
      type = types.str;
      default = "web.trev.zip";
      description = "Root domain routed to Garage website buckets.";
    };

    adminDomain = mkOption {
      type = types.str;
      default = "admin.trev.zip";
      description = "Domain routed to the Garage admin API.";
    };

    cacheDomain = mkOption {
      type = types.str;
      default = "nix.trev.zip";
      description = "Domain routed to the Nix binary cache bucket.";
    };

    rpcSecret = mkOption {
      type = secretType;
      default = {
        ref = "garage-rpc";
        file = self + /secrets/garage-rpc.age;
      };
      description = "Garage RPC secret.";
    };

    adminSecret = mkOption {
      type = secretType;
      default = {
        ref = "garage-admin";
        file = self + /secrets/garage-admin.age;
      };
      description = "Garage admin token secret.";
    };

    metricsSecret = mkOption {
      type = secretType;
      default = {
        ref = "garage-metrics";
        file = self + /secrets/garage-metrics.age;
      };
      description = "Garage metrics token secret.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes = {
      garage-s3 = {
        domains = [
          cfg.s3Domain
          "*.${cfg.s3Domain}"
        ];
        port = 3900;
      };
      garage-web = {
        # cacheDomain is served as the website of the bucket aliased to it.
        domains = [
          cfg.webDomain
          "*.${cfg.webDomain}"
          cfg.cacheDomain
        ];
        port = 3901;
      };
      garage-admin = {
        domains = [ cfg.adminDomain ];
        port = 3902;
      };
    };

    virtualisation.quadlet = {
      containers.garage.serviceConfig = {
        LogRateLimitIntervalSec = "30s";
        LogRateLimitBurst = "500";
      };

      secrets = {
        ${cfg.rpcSecret.ref} = cfg.rpcSecret;
        ${cfg.adminSecret.ref} = cfg.adminSecret;
        ${cfg.metricsSecret.ref} = cfg.metricsSecret;
      };

      containers.garage.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        environments.RUST_LOG = "garage=warn";
        volumes = [
          "${configFile}:/etc/garage.toml"
          "${volumes.garage.ref}:/meta"
          "${cfg.dataPath}:/data"
        ];
        secrets = [
          {
            inherit (cfg.rpcSecret) ref;
            type = "mount";
            target = "/secrets/rpc-secret";
            mode = "0400";
          }
          {
            inherit (cfg.adminSecret) ref;
            type = "mount";
            target = "/secrets/admin-token";
            mode = "0400";
          }
          {
            inherit (cfg.metricsSecret) ref;
            type = "mount";
            target = "/secrets/metrics-token";
            mode = "0400";
          }
        ];
        publishPorts = [
          "3900:3900" # s3
          "3901:3901" # web
          "3902:3902" # admin
        ];
      };

      volumes.garage = { };
    };
  };
}
