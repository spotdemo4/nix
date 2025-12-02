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
          image = "ghcr.io/imagegenius/immich:2.3.1@sha256:a5594d1b59256b118fd888f81f659e8d6ab0deea6cc0da416837d06a7ace643e";
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
        image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:7c7a43a59e407b66eeeb5ca13f5f20293fe484ca1673da508266be5e3088aa96";
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
