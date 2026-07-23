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
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
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
  cfg = config.trev.containers.mysql;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
in
{
  options.trev.containers.mysql = {
    enable = mkEnableOption "MySQL container instances";

    instances = mkOption {
      default = { };
      description = "MySQL container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} MySQL container";

              image = mkImageOption "docker.io/mysql:9.7.1@sha256:c109c421c81637a50209b57ec6af7dc0685e8b1ce7efdca0c0902a3d95df6574";

              database = mkOption {
                type = types.str;
                description = "Database name to create.";
              };

              username = mkOption {
                type = types.str;
                default = "root";
                description = "Database user to create.";
              };

              password = mkOption {
                type = secretType;
                description = "Podman secret reference containing the database password.";
              };

              networks = networks;
              publishPorts = publishPorts;

              volumeName = mkOption {
                type = types.str;
                default = "mysql-${name}";
                description = "Name of the generated persistent data volume.";
              };

              ref = mkOption {
                type = types.str;
                default = "mysql-${name}";
                description = "Reference name for the MySQL container.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (cfg.enable && enabledInstances != { }) {
    virtualisation.quadlet = {
      containers = mapAttrs' (
        _: instance:
        nameValuePair instance.ref {
          containerConfig = mkContainer {
            image = instance.image;
            pull = "missing";
            healthCmd = "mysqladmin ping -h localhost";
            notify = "healthy";
            volumes = [
              "${volumes.${instance.volumeName}.ref}:/var/lib/mysql"
            ];
            environments = {
              MYSQL_DATABASE = instance.database;
              MYSQL_USER = instance.username;
            };
            secrets = [
              {
                inherit (instance.password) ref;
                type = "env";
                target = "MYSQL_PASSWORD";
              }
              {
                inherit (instance.password) ref;
                type = "env";
                target = "MYSQL_ROOT_PASSWORD";
              }
            ];
            networks = instance.networks;
            publishPorts = instance.publishPorts;
          };
        }
      ) enabledInstances;

      volumes = mapAttrs' (_: instance: nameValuePair instance.volumeName { }) enabledInstances;
    };
  };
}
