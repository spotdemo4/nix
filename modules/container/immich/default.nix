{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) postgresql valkey;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/postgresql.nix)
    (self + /modules/container/valkey)
  ];

  postgresql."immich" = {
    database = "immich";
    username = "immich";
    password = "immich";
    networks = [
      networks."immich".ref
    ];
  };

  valkey."immich" = {
    networks = [
      networks."immich".ref
    ];
  };

  virtualisation.quadlet = {
    containers.immich.containerConfig = {
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

        DB_HOSTNAME = postgresql."immich".ref;
        DB_USERNAME = postgresql."immich".username;
        DB_PASSWORD = postgresql."immich".password;
        DB_DATABASE_NAME = postgresql."immich".database;

        REDIS_HOSTNAME = valkey."immich".ref;
      };
      volumes = [
        "${volumes."immich".ref}:/config"
        "/mnt/pool/photos:/photos"
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

    volumes = {
      immich = { };
    };

    networks = {
      immich = { };
    };
  };
}
