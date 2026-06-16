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
        image = "ghcr.io/shlinkio/shlink:5.1.3@sha256:c1e2b7e7a2375e83e2faa6d8f51d3f707f7eb8abab07c409301f5319ecb6825d";
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
