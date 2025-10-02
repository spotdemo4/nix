{
  lib,
  config,
  self,
  ...
}:
with lib; let
  inherit (config.virtualisation.quadlet) volumes;
in {
  options.postgresql = mkOption {
    default = {};
    description = "postgresql container configuration";

    type = types.attrsOf (types.submodule ({name, ...}: {
      options = {
        database = mkOption {
          type = types.str;
        };

        username = mkOption {
          type = types.str;
          default = "root";
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        passwordSecret = mkOption {
          type = types.nullOr (types.submodule (import (self + /modules/util/secrets/secret.nix)));
          default = null;
        };

        networks = mkOption {
          type = types.listOf types.str;
          default = [];
        };

        ref = mkOption {
          type = types.str;
          default = "postgresql-${name}";
        };
      };
    }));
  };

  config = mkIf (config.postgresql != {}) {
    virtualisation.quadlet = {
      containers = mapAttrs' (name: opts:
        nameValuePair "postgresql-${name}" {
          containerConfig = {
            image = "docker.io/postgres:17.6-alpine@sha256:d8bb4852e30c168a99654c9fa0673f51e4419cf96e931dbfe163fd8680bf1dba";
            pull = "missing";
            healthCmd = "pg_isready -U ${opts.username} -d ${opts.database}";
            notify = "healthy";
            volumes = [
              "${volumes."postgresql-${name}".ref}:/var/lib/postgresql"
            ];
            environments = {
              POSTGRES_DB = opts.database;
              POSTGRES_USER = opts.username;
              POSTGRES_PASSWORD = mkIf (opts.password != null) opts.password;
              PGDATA = "/var/lib/postgresql/17/docker";
            };
            secrets = mkIf (opts.passwordSecret != null) [
              "${opts.password.env},target=POSTGRES_PASSWORD"
            ];
            networks = opts.networks;
          };
        })
      config.postgresql;

      volumes = mapAttrs' (name: _: nameValuePair "postgresql-${name}" {}) config.postgresql;
    };
  };
}
