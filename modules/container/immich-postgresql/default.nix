{
  config,
  lib,
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
  cfg = config.trev.containers.immich-postgresql;
  immich = lib.attrByPath [ "trev" "containers" "immich" ] { enable = false; } config;
  inherit (config.virtualisation.quadlet) volumes;
  networks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  immichNetwork = lib.attrByPath [ "immich" ] { ref = "immich"; } networks;
in
{
  options.trev.containers.immich-postgresql = {
    enable = mkEnableOption "Immich PostgreSQL container";
    image = containerOptions.mkImageOption "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:828081a755d3911a2d94f0a2be9f98570c07d52cf080fd310a9d6e4b83b73aa5";

    containerName = mkOption {
      type = types.str;
      default = "postgresql-immich";
      description = "Name of the Immich PostgreSQL container.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "postgresql-immich";
      description = "Name of the Immich PostgreSQL data volume.";
    };

    database = mkOption {
      type = types.str;
      default = "immich";
      description = "Database created for Immich.";
    };

    username = mkOption {
      type = types.str;
      default = "postgres";
      description = "Database user used by Immich.";
    };

    passwordSecret = mkOption {
      type = types.nullOr containerOptions.secretReferenceType;
      default = null;
      description = "Podman secret reference containing the database password.";
    };

    networks = containerOptions.networks // {
      default = [ immichNetwork.ref ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = immich.enable;
        message = "trev.containers.immich-postgresql requires trev.containers.immich.enable = true";
      }
      {
        assertion = cfg.passwordSecret != null;
        message = "trev.containers.immich-postgresql.passwordSecret must reference a Podman secret";
      }
    ];

    virtualisation.quadlet = {
      containers.${cfg.containerName}.containerConfig = {
        image = cfg.image;
        pull = "missing";
        healthCmd = "pg_isready -U ${cfg.username} -d ${cfg.database}";
        notify = "healthy";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/var/lib/postgresql"
        ];
        networks = cfg.networks;
        environments = {
          POSTGRES_USER = cfg.username;
          POSTGRES_DB = cfg.database;
        };
        secrets = optional (
          cfg.passwordSecret != null
        ) "${cfg.passwordSecret.env},target=POSTGRES_PASSWORD";
      };

      volumes.${cfg.volumeName} = { };
    };
  };
}
