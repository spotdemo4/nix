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
        image = "ghcr.io/imagegenius/immich:2.6.1@sha256:324f159e3fa3cb4c81eff18095448592d9210a60f1eee8badc6627e86275cef4";
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
