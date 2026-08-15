{
  self,
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
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    networks
    publishPorts
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.postgresql;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
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

              image = mkImageOption "docker.io/postgres:18.6-alpine@sha256:d3e1620b530c944afa6e887d22eb899824da68e19c52024bf98f5220c88a65b2";

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
                type = types.nullOr secretType;
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
            containerConfig = mkContainer {
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
              secrets = optional (instance.passwordSecret != null) {
                inherit (instance.passwordSecret) ref;
                type = "env";
                target = "POSTGRES_PASSWORD";
              };
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
