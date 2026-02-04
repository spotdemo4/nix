{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.shlink-web = {
      containerConfig = {
        image = "docker.io/shlinkio/shlink-web-client:4.7.0@sha256:80b4d00c445f61e38164a4f13bea4f915b0bdc051e74705fe21ffa92a3d6fed5";
        pull = "missing";
        secrets = [
          "${secrets."shlink".env},target=SHLINK_SERVER_API_KEY"
        ];
        environments = {
          SHLINK_SERVER_URL = "https://trev.rs";
        };
        publishPorts = [
          "8080"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http = {
              middlewares.shlink-web-redirect = {
                redirectRegex = {
                  regex = "^https://trev\\.rs/";
                  replacement = "https://s.trev.rs/";
                };
              };
              routers = {
                shlink-web = {
                  rule = "Host(`s.trev.rs`)";
                  middlewares = "secure-admin@file";
                };
                shlink-web-redirect = {
                  rule = "Host(`trev.rs`) && Path(`/`) && Method(`GET`)";
                  middlewares = "shlink-web-redirect@redis";
                  service = "noop@internal";
                };
              };
            };
          };
        };
      };

      unitConfig = {
        After = containers."shlink".ref;
        BindsTo = containers."shlink".ref;
      };
    };
  };
}
