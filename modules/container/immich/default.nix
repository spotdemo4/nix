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
        image = "ghcr.io/imagegenius/immich:2.5.6@sha256:d9b41844bb519b47cdd940d6a6002bb02007abc7b9ca1658807d3129760c48af";
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
