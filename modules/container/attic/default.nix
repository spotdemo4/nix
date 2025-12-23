{
  config,
  self,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks;
  inherit (config) secrets postgresql;
  toLabel = import (self + /modules/util/label);

  cfg = pkgs.replaceVars ./server.toml {
    pgDb = postgresql."attic".database;
    pgUser = postgresql."attic".username;
    pgPass = postgresql."attic".password;
    pgHost = postgresql."attic".ref;
  };
in
{
  imports = [ (self + /modules/container/postgresql.nix) ];

  secrets."attic".file = self + /secrets/attic.age;

  postgresql."attic" = {
    database = "attic";
    username = "attic";
    password = "attic";
    networks = [
      networks."attic".ref
    ];
  };

  virtualisation.quadlet = {
    containers.attic = {
      containerConfig = {
        image = "ghcr.io/zhaofengli/attic:latest@sha256:18574aba70fc89d2b695273fbe2e7b2f8ad7e8e786b4cc535124fbe14bada1d0";
        pull = "missing";
        secrets = [
          "${secrets."attic".env},target=ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64"
        ];
        volumes = [
          "/mnt/cache:/cache"
          "${cfg}:/server.toml"
        ];
        publishPorts = [
          "8080"
        ];
        networks = [
          networks."attic".ref
        ];
        exec = "--config /server.toml";
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.attic = {
              rule = "Host(`cache.trev.zip`)";
              middlewares = "secure@file";
            };
          };
        };
      };

      unitConfig = {
        After = containers."postgresql-attic".ref;
        BindsTo = containers."postgresql-attic".ref;
      };
    };

    networks = {
      attic = { };
    };
  };
}
