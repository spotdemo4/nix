{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks;
  inherit (config) secrets postgresql;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/postgresql)
    ./web.nix
  ];

  secrets = {
    "geolite".file = self + /secrets/geolite.age;
    "shlink".file = self + /secrets/shlink.age;
  };

  postgresql."shlink" = {
    database = "shlink";
    username = "shlink";
    password = "shlink";
    networks = [
      networks."shlink".ref
    ];
  };

  virtualisation.quadlet = {
    containers.shlink = {
      containerConfig = {
        image = "ghcr.io/shlinkio/shlink:5.0.1@sha256:a6d8508bc6b0eba5a28e1ee8b64dd5253434cd113c950e715baab4020edcd2a1";
        pull = "missing";
        secrets = [
          "${secrets."geolite".env},target=GEOLITE_LICENSE_KEY"
          "${secrets."shlink".env},target=INITIAL_API_KEY"
        ];
        environments = {
          DEFAULT_DOMAIN = "trev.rs";
          IS_HTTPS_ENABLED = "true";

          DB_DRIVER = "postgres";
          DB_NAME = postgresql."shlink".database;
          DB_USER = postgresql."shlink".username;
          DB_PASSWORD = postgresql."shlink".password;
          DB_HOST = postgresql."shlink".ref;
        };
        networks = [
          networks."shlink".ref
        ];
        publishPorts = [
          "8080"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.shlink = {
              rule = "Host(`trev.rs`)";
            };
          };
        };
      };

      unitConfig = {
        After = containers."postgresql-shlink".ref;
        BindsTo = containers."postgresql-shlink".ref;
      };
    };

    networks = {
      shlink = { };
    };
  };
}
