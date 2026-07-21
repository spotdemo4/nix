{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    containers
    networks
    ;
  cfg = config.trev.containers.niks3;
  postgresql = lib.attrByPath [ "trev" "containers" "postgresql" ] {
    enable = false;
    instances = { };
  } config;
  database = lib.attrByPath [ "instances" "niks3" ] {
    enable = false;
    username = "";
    passwordSecret = null;
    ref = "postgresql-niks3";
    database = "";
  } postgresql;
  databaseContainer = lib.attrByPath [ "postgresql-niks3" ] { ref = "postgresql-niks3"; } containers;
in
{
  options.trev.containers.niks3 = {
    enable = mkEnableOption "Niks3 container";
    image = mkImageOption "ghcr.io/mic92/niks3:main@sha256:3f087a3b59202b333a89e414e732f03b5e43d13f187a4e46a639a6f499472e34";

    domain = mkOption {
      type = types.str;
      default = "niks3.trev.zip";
      description = "Domain routed to Niks3.";
    };

    cacheUrl = mkOption {
      type = types.str;
      default = "https://nix.trev.zip";
      description = "Public URL of the Nix binary cache.";
    };

    s3Endpoint = mkOption {
      type = types.str;
      default = "s3.trev.zip";
      description = "S3 endpoint used by Niks3.";
    };

    s3Bucket = mkOption {
      type = types.str;
      default = "nix";
      description = "S3 bucket used by Niks3.";
    };

    oidcConfigFile = mkOption {
      type = types.either types.path types.str;
      default = ./oidc.json;
      description = "OIDC provider configuration mounted into Niks3.";
    };

    apiTokenSecret = mkOption {
      type = secretType;
      default = {
        ref = "niks3";
        file = self + /secrets/niks3.age;
      };
      description = "Niks3 API token secret.";
    };

    signingKeySecret = mkOption {
      type = secretType;
      default = {
        ref = "niks3-signing-key";
        file = self + /secrets/niks3-signing-key.age;
      };
      description = "Niks3 signing key secret.";
    };

    s3AccessKeySecret = mkOption {
      type = secretType;
      default = {
        ref = "garage-nix-key";
        file = self + /secrets/garage-nix-key.age;
      };
      description = "S3 access key secret.";
    };

    s3SecretKeySecret = mkOption {
      type = secretType;
      default = {
        ref = "garage-nix-secret";
        file = self + /secrets/garage-nix-secret.age;
      };
      description = "S3 secret key secret.";
    };

    databaseUrlSecret = mkOption {
      type = types.nullOr secretType;
      default = null;
      description = "Podman secret reference containing the complete Niks3 PostgreSQL connection string.";
    };

    port = mkOption {
      type = types.port;
      default = 5751;
      description = "Niks3 HTTP port to publish.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = postgresql.enable;
        message = "trev.containers.niks3 requires trev.containers.postgresql.enable = true";
      }
      {
        assertion = database.enable;
        message = "trev.containers.niks3 requires trev.containers.postgresql.instances.niks3.enable = true";
      }
      {
        assertion = database.passwordSecret != null;
        message = "trev.containers.niks3 requires trev.containers.postgresql.instances.niks3.passwordSecret to reference a Podman secret";
      }
      {
        assertion = cfg.databaseUrlSecret != null;
        message = "trev.containers.niks3.databaseUrlSecret must reference a Podman secret containing the complete connection string";
      }
    ];

    virtualisation.quadlet = {
      secrets = {
        ${cfg.apiTokenSecret.ref} = cfg.apiTokenSecret;
        ${cfg.signingKeySecret.ref} = cfg.signingKeySecret;
        ${cfg.s3AccessKeySecret.ref} = cfg.s3AccessKeySecret;
        ${cfg.s3SecretKeySecret.ref} = cfg.s3SecretKeySecret;
      };

      containers.niks3 = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          environments = {
            NIKS3_CACHE_URL = cfg.cacheUrl;
            NIKS3_S3_ENDPOINT = cfg.s3Endpoint;
            NIKS3_S3_BUCKET = cfg.s3Bucket;
            NIKS3_SIGN_KEY_PATHS = "/secrets/signing-key";
            NIKS3_OIDC_CONFIG = "/config/oidc.json";
          };
          secrets = [
            {
              inherit (cfg.apiTokenSecret) ref;
              type = "env";
              target = "NIKS3_API_TOKEN";
            }
            {
              inherit (cfg.signingKeySecret) ref;
              type = "mount";
              target = "/secrets/signing-key";
            }
            {
              inherit (cfg.s3AccessKeySecret) ref;
              type = "env";
              target = "NIKS3_S3_ACCESS_KEY";
            }
            {
              inherit (cfg.s3SecretKeySecret) ref;
              type = "env";
              target = "NIKS3_S3_SECRET_KEY";
            }
          ]
          ++ optional (cfg.databaseUrlSecret != null) {
            inherit (cfg.databaseUrlSecret) ref;
            type = "env";
            target = "NIKS3_DB";
          };
          volumes = [
            "${cfg.oidcConfigFile}:/config/oidc.json"
          ];
          networks = [
            networks.niks3.ref
          ];
          publishPorts = [
            (toString cfg.port)
          ];
          labels = {
            traefik = {
              enable = true;
              http.routers.niks3.rule = "Host(`${cfg.domain}`)";
            };
          };
        };

        unitConfig = {
          After = databaseContainer.ref;
          BindsTo = databaseContainer.ref;
        };
      };

      networks.niks3 = { };
    };
  };
}
