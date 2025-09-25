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
          type = types.str;
          default = null;
        };

        passwordSecret = mkOption {
          type = types.submodule (import (self + /modules/util/secrets/secret.nix));
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
            image = "docker.io/postgres:17.6-alpine@sha256:855021a5b10954343902a8c22a15f8464233126c1d12d9ad84d4a14c5af07a80";
            pull = "missing";
            healthCmd = "pg_isready";
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
