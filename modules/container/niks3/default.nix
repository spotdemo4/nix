{
  config,
  lib,
  pkgs,
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
  gcCommand = pkgs.writeShellApplication {
    name = "niks3-gc";
    runtimeInputs = [ pkgs.podman ];
    text = ''
      exec podman exec niks3 niks3 gc \
        --server-url=${lib.escapeShellArg "http://127.0.0.1:${toString cfg.port}"} \
        --auth-token-path=/run/secrets/niks3-api-token \
        --older-than=${lib.escapeShellArg cfg.gc.olderThan} \
        --failed-uploads-older-than=${lib.escapeShellArg cfg.gc.failedUploadsOlderThan}
    '';
  };
in
{
  options.trev.containers.niks3 = {
    enable = mkEnableOption "Niks3 container";
    image = mkImageOption "ghcr.io/mic92/niks3:main@sha256:1da38727ef34fd3cdb7c66204f70c53bb802dcfd4d47876de0288343cc64be66";

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

    gc = {
      enable = mkEnableOption "automatic Niks3 garbage collection";

      olderThan = mkOption {
        type = types.str;
        default = "720h";
        description = "Minimum age of closures to garbage collect.";
      };

      failedUploadsOlderThan = mkOption {
        type = types.str;
        default = "6h";
        description = "Minimum age of failed uploads to garbage collect.";
      };

      schedule = mkOption {
        type = types.str;
        default = "daily";
        description = "Systemd calendar expression for garbage collection.";
      };

      randomizedDelaySec = mkOption {
        type = types.str;
        default = "30m";
        description = "Maximum randomized delay before garbage collection.";
      };

      timeout = mkOption {
        type = types.str;
        default = "2h";
        description = "Maximum duration of a garbage collection run.";
      };
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
          notify = true;
          environments = {
            NIKS3_API_TOKEN_PATH = "/run/secrets/niks3-api-token";
            NIKS3_CACHE_URL = cfg.cacheUrl;
            NIKS3_S3_ENDPOINT = cfg.s3Endpoint;
            NIKS3_S3_BUCKET = cfg.s3Bucket;
            NIKS3_SIGN_KEY_PATHS = "/secrets/signing-key";
            NIKS3_OIDC_CONFIG = "/config/oidc.json";
          };
          secrets = [
            {
              inherit (cfg.apiTokenSecret) ref;
              type = "mount";
              target = "/run/secrets/niks3-api-token";
              uid = 0;
              gid = 0;
              mode = "0400";
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

    systemd.services.niks3-gc = mkIf cfg.gc.enable {
      description = "Niks3 garbage collection";
      requires = [ "niks3.service" ];
      after = [ "niks3.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe gcCommand;
        TimeoutStartSec = cfg.gc.timeout;
      };
    };

    systemd.timers.niks3-gc = mkIf cfg.gc.enable {
      description = "Niks3 garbage collection timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.gc.schedule;
        RandomizedDelaySec = cfg.gc.randomizedDelaySec;
        Persistent = true;
      };
    };
  };
}
