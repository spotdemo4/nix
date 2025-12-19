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

    volumes = {
      postgresql-immich = { };
    };
  };
}
