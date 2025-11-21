{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) valkey;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/valkey)
  ];

  valkey."immich" = {
    networks = [
      networks."immich".ref
    ];
  };

  virtualisation.quadlet = {
    containers = {
      immich = {
        containerConfig = {
          image = "ghcr.io/imagegenius/immich:2.3.1@sha256:447ef17217ca08588d787249b65a0bb988e942449c8c047515c8da3cab67824d";
          pull = "missing";
          devices = [
            "/dev/dri/card0:/dev/dri/card0"
            "/dev/dri/renderD128:/dev/dri/renderD128"
          ];
          environments = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/Detroit";

            DB_HOSTNAME = "postgresql-immich";
            DB_USERNAME = "postgres";
            DB_PASSWORD = "postgres";
            DB_DATABASE_NAME = "immich";

            REDIS_HOSTNAME = valkey."immich".ref;
          };
          volumes = [
            "${volumes."immich".ref}:/config"
            "/mnt/photos:/photos"
          ];
          publishPorts = [
            "8080"
          ];
          networks = [
            networks."immich".ref
          ];
          labels = toLabel {
            attrs = {
              traefik = {
                enable = true;
                http.routers.immich = {
                  rule = "HostRegexp(`photos.trev.(xyz|zip)`)";
                };
              };
            };
          };
        };

        unitConfig = {
          After = [
            "postgresql-immich"
            valkey."immich".ref
          ];
          BindsTo = [
            "postgresql-immich"
            valkey."immich".ref
          ];
        };
      };

      postgresql-immich.containerConfig = {
        image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:84fb60d4bfe0556761d36319e0e12c7635911ab50f74353119a74653b462b750";
        pull = "missing";
        healthCmd = "pg_isready -U postgres -d immich";
        notify = "healthy";
        volumes = [
          "${volumes."postgresql-immich".ref}:/var/lib/postgresql"
        ];
        networks = [
          networks."immich".ref
        ];
        environments = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "immich";
        };
      };
    };

    volumes = {
      immich = { };
      postgresql-immich = { };
    };

    networks = {
      immich = { };
    };
  };
}
