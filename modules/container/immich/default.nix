{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks volumes;
  inherit (config) valkey;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/valkey)
    ./postgres.nix
  ];

  valkey."immich" = {
    networks = [
      networks."immich".ref
    ];
  };

  virtualisation.quadlet = {
    containers.immich = {
      containerConfig = {
        image = "ghcr.io/imagegenius/immich:2.5.0@sha256:02d082981fc2a793b6de82ab9da012a2ec7e2dcf749d3078f774f37c0a7eaf07";
        pull = "missing";
        devices = [
          "/dev/dri/card0:/dev/dri/card0"
          "/dev/dri/renderD128:/dev/dri/renderD128"
        ];
        environments = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Detroit";

          DB_HOSTNAME = containers."postgresql-immich".ref;
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
          attrs.traefik = {
            enable = true;
            http.routers.immich = {
              rule = "Host(`photos.trev.zip`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      unitConfig = {
        After = containers."postgresql-immich".ref;
        BindsTo = containers."postgresql-immich".ref;
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
