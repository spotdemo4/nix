{
  self,
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
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    ;
  cfg = config.trev.containers.immich;
  database = lib.attrByPath [ "trev" "containers" "immich-postgresql" ] {
    enable = false;
    containerName = "postgresql-immich";
    username = "";
    passwordSecret = null;
    database = "";
  } config;
  valkeyConfig = lib.attrByPath [ "trev" "containers" "valkey" ] {
    enable = false;
    instances = { };
  } config;
  valkey = lib.attrByPath [ "instances" "immich" ] {
    enable = false;
    ref = "valkey-immich";
  } valkeyConfig;
  inherit (config.virtualisation.quadlet) containers networks volumes;
  databaseContainer = lib.attrByPath [ database.containerName ] {
    ref = database.containerName;
  } containers;
in
{
  options.trev.containers.immich = {
    enable = mkEnableOption "Immich container";
    image = mkImageOption "ghcr.io/imagegenius/immich:3.0.3@sha256:45abbf8a52f14f5166640fe2f4f2067cd00a87df27694b4d39d80ad0ac78c9ec";

    photosPath = mkOption {
      type = types.str;
      default = "/mnt/photos";
      description = "Host path containing the photo library.";
    };

    domain = mkOption {
      type = types.str;
      default = "photos.trev.zip";
      description = "Domain routed to Immich.";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [
        "/dev/dri/card0:/dev/dri/card0"
        "/dev/dri/renderD128:/dev/dri/renderD128"
      ];
      description = "Host devices passed through to Immich.";
    };

    userId = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Immich.";
    };

    groupId = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Immich.";
    };

    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Timezone used by Immich.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Immich HTTP port to publish.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = database.enable;
        message = "trev.containers.immich requires trev.containers.immich-postgresql.enable = true";
      }
      {
        assertion = database.passwordSecret != null;
        message = "trev.containers.immich requires trev.containers.immich-postgresql.passwordSecret to reference a Podman secret";
      }
      {
        assertion = valkeyConfig.enable && valkey.enable;
        message = "trev.containers.immich requires trev.containers.valkey.enable = true and trev.containers.valkey.instances.immich.enable = true";
      }
    ];

    virtualisation.quadlet = {
      containers.immich = {
        containerConfig = mkContainer {
          image = cfg.image;
          pull = "missing";
          devices = cfg.devices;
          environments = {
            PUID = toString cfg.userId;
            PGID = toString cfg.groupId;
            TZ = cfg.timeZone;

            DB_HOSTNAME = databaseContainer.ref;
            DB_USERNAME = database.username;
            DB_DATABASE_NAME = database.database;

            REDIS_HOSTNAME = valkey.ref;
          };
          secrets = optional (database.passwordSecret != null) {
            inherit (database.passwordSecret) ref;
            type = "env";
            target = "DB_PASSWORD";
          };
          volumes = [
            "${volumes.immich.ref}:/config"
            "${cfg.photosPath}:/photos"
          ];
          publishPorts = [
            (toString cfg.port)
          ];
          networks = [
            networks.immich.ref
          ];
          labels = {
            traefik = {
              enable = true;
              http.routers.immich = {
                rule = "Host(`${cfg.domain}`)";
                middlewares = "secure@file";
              };
            };
          };
        };

        unitConfig = {
          After = databaseContainer.ref;
          BindsTo = databaseContainer.ref;
        };
      };

      volumes.immich = { };
      networks.immich = { };
    };
  };
}
