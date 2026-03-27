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
      image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:291316e3f152718d4608cd39bbb8f05f2528403fbef4a4e1c33f6d4bc23d7ac5";
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
