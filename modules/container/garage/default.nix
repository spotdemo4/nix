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
    replaceStrings
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
  s3DomainPattern = replaceStrings [ "." ] [ "\\." ] cfg.s3Domain;
  webDomainPattern = replaceStrings [ "." ] [ "\\." ] cfg.webDomain;
in
{
  options.trev.containers.garage = {
    enable = mkEnableOption "Garage container";
    image = mkImageOption "docker.io/dxflrs/garage:v2.3.0@sha256:866bd13ed2038ba7e7190e840482bc27234c4afaf77be8cfa439ae088c1e4690";

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
    virtualisation.quadlet = {
      secrets = {
        ${cfg.rpcSecret.ref} = cfg.rpcSecret;
        ${cfg.adminSecret.ref} = cfg.adminSecret;
        ${cfg.metricsSecret.ref} = cfg.metricsSecret;
      };

      containers.garage.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
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
        labels = {
          traefik = {
            enable = true;
            http = {
              middlewares = {
                nix-cache = {
                  headers.customrequestheaders = {
                    Host = "nix.${cfg.webDomain}";
                    X-Forwarded-Host = "nix.${cfg.webDomain}";
                  };
                };
              };
              routers = {
                garage-s3 = {
                  rule = "Host(`${cfg.s3Domain}`) || HostRegexp(`^.+\\.${s3DomainPattern}$`)";
                  service = "garage-s3";
                };
                garage-web = {
                  rule = "Host(`${cfg.webDomain}`) || HostRegexp(`^.+\\.${webDomainPattern}$`)";
                  service = "garage-web";
                  middlewares = "secure@file";
                };
                garage-admin = {
                  rule = "Host(`${cfg.adminDomain}`)";
                  service = "garage-admin";
                  middlewares = "secure@file";
                };
                nix-cache = {
                  rule = "Host(`${cfg.cacheDomain}`)";
                  service = "garage-web";
                  middlewares = "nix-cache@redis";
                };
              };
              services = {
                garage-s3.loadbalancer.server.port = 3900;
                garage-web.loadbalancer.server.port = 3901;
                garage-admin.loadbalancer.server.port = 3902;
              };
            };
          };
        };
      };

      volumes.garage = { };
    };
  };
}
