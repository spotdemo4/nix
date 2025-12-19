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
        image = "docker.io/shlinkio/shlink-web-client:4.6.2@sha256:93d4c24ca33d856e8e8076232eed6f5e5b01c70d705fdeae63fc7ae4034ea07d";
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
