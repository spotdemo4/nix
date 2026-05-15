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
        image = "docker.io/shlinkio/shlink-web-client:4.7.1@sha256:acc95a754a52d2a2aa4e74da6f722180e5b209902f0f0aad7cd9df33d4b4fc6f";
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
