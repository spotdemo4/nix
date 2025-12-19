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
  imports = [ (self + /modules/container/postgresql.nix) ];

  secrets."geolite".file = self + /secrets/geolite.age;

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
        image = "ghcr.io/shlinkio/shlink:4.6.0@sha256:e607cd6f8c7f6bfd4cc734c812538d4123602c455a439c43dd02b35af885948f";
        pull = "missing";
        secrets = [
          "${secrets."geolite".env},target=GEOLITE_LICENSE_KEY"
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
