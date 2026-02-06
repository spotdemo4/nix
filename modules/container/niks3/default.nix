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
    "garage-nix-key".file = self + /secrets/garage-nix-key.age;
    "garage-nix-secret".file = self + /secrets/garage-nix-secret.age;
  };

  virtualisation.quadlet = {
    containers."niks3" = {
      containerConfig = {
        image = "ghcr.io/mic92/niks3:main@sha256:fe994b51ca9d6a9611820ce7ad754c09fd5c54e927aeca1cae1bb9cfeee55cb2";
        pull = "missing";
        environments = {
          NIKS3_DB = "postgres://${postgresql."niks3".username}:${postgresql."niks3".password}@${postgresql."niks3".ref}/${postgresql."niks3".database}?sslmode=disable";
          # NIKS3_CACHE_URL = "https://nix.web.trev.zip";
          NIKS3_S3_ENDPOINT = "s3.trev.zip";
          NIKS3_S3_BUCKET = "nix";
          NIKS3_SIGN_KEY_PATHS = "/secrets/signing-key";
        };
        secrets = [
          "${secrets."niks3".env},target=NIKS3_API_TOKEN"
          "${secrets."niks3-signing-key".mount},target=/secrets/signing-key"
          "${secrets."garage-nix-key".env},target=NIKS3_S3_ACCESS_KEY"
          "${secrets."garage-nix-secret".env},target=NIKS3_S3_SECRET_KEY"
        ];
        publishPorts = [
          "5751"
        ];
        networks = [
          networks."niks3".ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.niks3 = {
              rule = "Host(`niks.trev.zip`)";
              middlewares = "secure@file";
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
