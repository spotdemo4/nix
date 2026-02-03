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
      image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3@sha256:fb5d39e22bdda0950eec2786f57b1ef580161237e92684db261119662a6d4670";
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
