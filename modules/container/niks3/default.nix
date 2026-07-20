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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
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
  inherit (config.virtualisation.quadlet) containers networks;
  databaseContainer = lib.attrByPath [ "postgresql-niks3" ] { ref = "postgresql-niks3"; } containers;
  inherit (config) secrets;
  toLabel = import (self + /lib/label);
in
{
  options.trev.containers.niks3 = {
    enable = mkEnableOption "Niks3 container";
    image = containerOptions.mkImageOption "ghcr.io/mic92/niks3:main@sha256:3f087a3b59202b333a89e414e732f03b5e43d13f187a4e46a639a6f499472e34";

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

    apiTokenSecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/niks3.age;
      description = "Age-encrypted Niks3 API token.";
    };

    signingKeySecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/niks3-signing-key.age;
      description = "Age-encrypted Niks3 signing key.";
    };

    s3AccessKeySecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/garage-nix-key.age;
      description = "Age-encrypted S3 access key.";
    };

    s3SecretKeySecretFile = mkOption {
      type = types.either types.path types.str;
      default = self + /secrets/garage-nix-secret.age;
      description = "Age-encrypted S3 secret key.";
    };

    databaseUrlSecret = mkOption {
      type = types.nullOr containerOptions.secretReferenceType;
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

    secrets = {
      niks3.file = cfg.apiTokenSecretFile;
      niks3-signing-key.file = cfg.signingKeySecretFile;
      garage-nix-key.file = cfg.s3AccessKeySecretFile;
      garage-nix-secret.file = cfg.s3SecretKeySecretFile;
    };

    virtualisation.quadlet = {
      containers.niks3 = {
        containerConfig = {
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
            "${secrets.niks3.env},target=NIKS3_API_TOKEN"
            "${secrets.niks3-signing-key.mount},target=/secrets/signing-key"
            "${secrets.garage-nix-key.env},target=NIKS3_S3_ACCESS_KEY"
            "${secrets.garage-nix-secret.env},target=NIKS3_S3_SECRET_KEY"
          ]
          ++ optional (cfg.databaseUrlSecret != null) "${cfg.databaseUrlSecret.env},target=NIKS3_DB";
          volumes = [
            "${cfg.oidcConfigFile}:/config/oidc.json"
          ];
          networks = [
            networks.niks3.ref
          ];
          publishPorts = [
            (toString cfg.port)
          ];
          labels = toLabel {
            attrs.traefik = {
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
