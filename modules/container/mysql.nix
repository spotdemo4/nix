{
  lib,
  config,
  self,
  ...
}:
with lib; let
  inherit (config.virtualisation.quadlet) volumes;
in {
  options.mysql = mkOption {
    default = {};
    description = "mysql container configuration";

    type = types.attrsOf (types.submodule ({name, ...}: {
      options = {
        database = mkOption {
          type = types.str;
          description = "Database name to create";
        };

        username = mkOption {
          type = types.str;
          description = "Username to create";
          default = "root";
        };

        password = mkOption {
          type = types.submodule (import (self + /modules/util/secrets/secret.nix));
          description = "Password secret";
        };

        networks = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            Networks to connect mysql to
          '';
        };

        ref = mkOption {
          type = types.str;
          description = "Reference name for the mysql container";
          default = "mysql-${name}";
        };
      };
    }));
  };

  config = mkIf (config.mysql != {}) {
    virtualisation.quadlet = {
      containers = mapAttrs' (name: opts:
        nameValuePair "mysql-${name}" {
          containerConfig = {
            image = "docker.io/mysql:9.4.0@sha256:91447968e66961302339ec4dc4d385f5e1a957d98e63c7d52ecf8b1de0907346";
            pull = "missing";
            healthCmd = "mysqladmin ping -h localhost";
            notify = "healthy";
            volumes = [
              "${volumes."mysql-${name}".ref}:/var/lib/mysql"
            ];
            environments = {
              MYSQL_DATABASE = opts.database;
              MYSQL_USER = opts.username;
            };
            secrets = [
              "${opts.password.env},target=MYSQL_PASSWORD"
              "${opts.password.env},target=MYSQL_ROOT_PASSWORD"
            ];
            networks = opts.networks;
          };
        })
      config.mysql;

      volumes = mapAttrs' (name: _: nameValuePair "mysql-${name}" {}) config.mysql;
    };
  };
}
