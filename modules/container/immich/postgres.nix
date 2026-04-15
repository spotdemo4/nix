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
      image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:b2f93fb4d9c1c0c720d6bf61e26f237f0aed12dcb4109dfb447ef7ae9dc209ce";
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
