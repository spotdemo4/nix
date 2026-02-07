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
        image = "ghcr.io/mic92/niks3:main@sha256:1edabce56d3e359bfd327d1684e6b62948a7916ce4e0f3496c630c38f59a5615";
        pull = "missing";
        environments = {
          NIKS3_DB = "postgres://${postgresql."niks3".username}:${postgresql."niks3".password}@${postgresql."niks3".ref}/${postgresql."niks3".database}?sslmode=disable";
          NIKS3_CACHE_URL = "https://nix.trev.zip";
          NIKS3_S3_ENDPOINT = "s3.trev.zip";
          NIKS3_S3_BUCKET = "nix";
          NIKS3_SIGN_KEY_PATHS = "/secrets/signing-key";
          NIKS3_OIDC_CONFIG = "/config/oidc.json";
        };
        secrets = [
          "${secrets."niks3".env},target=NIKS3_API_TOKEN"
          "${secrets."niks3-signing-key".mount},target=/secrets/signing-key"
          "${secrets."garage-nix-key".env},target=NIKS3_S3_ACCESS_KEY"
          "${secrets."garage-nix-secret".env},target=NIKS3_S3_SECRET_KEY"
        ];
        volumes = [
          "${./oidc.json}:/config/oidc.json"
        ];
        networks = [
          networks."niks3".ref
        ];
        publishPorts = [
          "5751"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.niks3 = {
              rule = "Host(`niks3.trev.zip`)";
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
