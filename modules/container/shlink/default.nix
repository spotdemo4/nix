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
  cfg = config.trev.containers.shlink;
  postgresql = lib.attrByPath [ "trev" "containers" "postgresql" ] {
    enable = false;
    instances = { };
  } config;
  database = lib.attrByPath [ "instances" "shlink" ] {
    enable = false;
    database = "";
    username = "";
    passwordSecret = null;
    ref = "postgresql-shlink";
  } postgresql;
  databaseContainer = lib.attrByPath [ "postgresql-shlink" ] {
    ref = "postgresql-shlink";
  } containers;
in
{
  options.trev.containers.shlink = {
    enable = mkEnableOption "Shlink container";

    image = mkImageOption "ghcr.io/shlinkio/shlink:5.1.5@sha256:77b8eb87bcb1a56bd0ecc590398d415545e5ba83414f28d37dc565a91c3c50b2";

    domain = mkOption {
      type = types.str;
      default = "trev.rs";
      description = "Public Shlink domain.";
    };

    geoliteSecret = mkOption {
      type = secretType;
      default = {
        ref = "geolite";
        file = self + /secrets/geolite.age;
      };
      description = "GeoLite license key secret.";
    };

    apiSecret = mkOption {
      type = secretType;
      default = {
        ref = "shlink";
        file = self + /secrets/shlink.age;
      };
      description = "Initial Shlink API key secret.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = postgresql.enable;
        message = "trev.containers.shlink requires trev.containers.postgresql.enable = true";
      }
      {
        assertion = database.enable;
        message = "trev.containers.shlink requires trev.containers.postgresql.instances.shlink.enable = true";
      }
      {
        assertion = database.passwordSecret != null;
        message = "trev.containers.shlink requires trev.containers.postgresql.instances.shlink.passwordSecret to reference a Podman secret";
      }
    ];

    virtualisation.quadlet = {
      secrets = {
        ${cfg.geoliteSecret.ref} = cfg.geoliteSecret;
        ${cfg.apiSecret.ref} = cfg.apiSecret;
      };

      containers.shlink = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          secrets = [
            {
              inherit (cfg.geoliteSecret) ref;
              type = "env";
              target = "GEOLITE_LICENSE_KEY";
            }
            {
              inherit (cfg.apiSecret) ref;
              type = "env";
              target = "INITIAL_API_KEY";
            }
          ]
          ++ optional (database.passwordSecret != null) {
            inherit (database.passwordSecret) ref;
            type = "env";
            target = "DB_PASSWORD";
          };
          environments = {
            DEFAULT_DOMAIN = cfg.domain;
            IS_HTTPS_ENABLED = "true";

            DB_DRIVER = "postgres";
            DB_NAME = database.database;
            DB_USER = database.username;
            DB_HOST = database.ref;
          };
          networks = [
            networks.shlink.ref
          ];
          publishPorts = [ "8080" ];
          labels = {
            traefik = {
              enable = true;
              http.routers.shlink.rule = "Host(`${cfg.domain}`)";
            };
          };
        };

        unitConfig = {
          After = databaseContainer.ref;
          BindsTo = databaseContainer.ref;
        };
      };

      networks.shlink = { };
    };
  };
}
