{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optional
    types
    ;
  inherit (import ../../../lib/container-options.nix { inherit lib; })
    mkImageOption
    networks
    publishPorts
    secretReferenceType
    ;
  cfg = config.trev.containers.postgresql;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.trev.containers.postgresql = {
    enable = mkEnableOption "PostgreSQL container instances";

    instances = mkOption {
      default = { };
      description = "PostgreSQL container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} PostgreSQL container";

              image = mkImageOption "docker.io/postgres:18.4-alpine@sha256:9a8afca54e7861fd90fab5fdf4c42477a6b1cb7d293595148e674e0a3181de15";

              database = mkOption {
                type = types.str;
                description = "Database name to create.";
              };

              username = mkOption {
                type = types.str;
                default = "root";
                description = "Database user to create.";
              };

              passwordSecret = mkOption {
                type = types.nullOr secretReferenceType;
                default = null;
                description = "Podman secret reference containing the database password.";
              };

              networks = networks;
              publishPorts = publishPorts;

              volumeName = mkOption {
                type = types.str;
                default = "postgresql-${name}";
                description = "Name of the generated persistent data volume.";
              };

              ref = mkOption {
                type = types.str;
                default = "postgresql-${name}";
                description = "Reference name for the PostgreSQL container.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = mapAttrsToList (name: instance: {
        assertion = instance.passwordSecret != null;
        message = "trev.containers.postgresql.instances.${name}.passwordSecret must reference a Podman secret";
      }) enabledInstances;
    }

    (mkIf (enabledInstances != { }) {
      virtualisation.quadlet = {
        containers = mapAttrs' (
          _: instance:
          nameValuePair instance.ref {
            containerConfig = {
              image = instance.image;
              pull = "missing";
              healthCmd = "pg_isready -U ${instance.username} -d ${instance.database}";
              notify = "healthy";
              volumes = [
                "${volumes.${instance.volumeName}.ref}:/var/lib/postgresql"
              ];
              environments = {
                POSTGRES_DB = instance.database;
                POSTGRES_USER = instance.username;
                PGDATA = "/var/lib/postgresql/18/docker";
              };
              secrets = optional (
                instance.passwordSecret != null
              ) "${instance.passwordSecret.env},target=POSTGRES_PASSWORD";
              networks = instance.networks;
              publishPorts = instance.publishPorts;
            };
          }
        ) enabledInstances;

        volumes = mapAttrs' (_: instance: nameValuePair instance.volumeName { }) enabledInstances;
      };
    })
  ]);
}
