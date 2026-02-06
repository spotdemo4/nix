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

  postgresql."niks3" = {
    database = "niks3";
    username = "niks3";
    password = "niks3";
    networks = [
      networks."niks3".ref
    ];
  };

  secrets = {
    "niks3".file = self + /secrets/niks3.age;
    "niks3-signing-key".file = self + /secrets/niks3-signing-key.age;
  };

  virtualisation.quadlet = {
    containers."niks3" = {
      containerConfig = {
        image = "ghcr.io/mic92/niks3:v1.2.0@sha256:4d788d7a4e1fce4fe331360e99f16734a4bb22c86cd98e9d1032c195d4a18efd";
        pull = "missing";
        environments = {
          NIKS3_DB = "postgres://${postgresql."niks3".username}:${postgresql."niks3".password}@${postgresql."niks3".ref}/${postgresql."niks3".database}?sslmode=disable";
          NIKS3_S3_ENDPOINT = "http://${containers."versitygw".ref}:7070";
          NIKS3_S3_BUCKET = "nix";
          NIKS3_S3_ACCESS_KEY = "trev";
          NIKS3_SIGN_KEY_PATHS = "/secrets/signing-key";
        };
        secrets = [
          "${secrets."versitygw".env},target=NIKS3_S3_SECRET_KEY"
          "${secrets."niks3".env},target=NIKS3_API_TOKEN"
          "${secrets."niks3-signing-key".mount},target=/secrets/signing-key"
        ];
        publishPorts = [
          "5751"
        ];
        networks = [
          networks."niks3".ref
          networks."versitygw".ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.niks3 = {
              rule = "Host(`niks3.trev.zip`)";
            };
          };
        };
      };

      unitConfig = {
        After = containers."postgresql-niks3".ref;
        BindsTo = containers."postgresql-niks3".ref;
      };
    };

    networks = {
      niks3 = { };
    };
  };
}
