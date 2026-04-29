{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
in
{
  virtualisation.quadlet = {
    containers.postgresql-immich.containerConfig = {
      image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:ef431845dc61cdc061a2f2ff2ba927e87868e10ffd3d7e689a79fba061b043c0";
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

    volumes = {
      postgresql-immich = { };
    };
  };
}
