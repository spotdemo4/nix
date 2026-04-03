{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.seaweedfs-admin = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.18@sha256:37ff8b1c2aff48edc2ac4439d0c5b0b73a9ee100e0ab93c68e6bceb00d1cba28";
        pull = "missing";
        publishPorts = [
          "8080"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        volumes = [
          "${volumes."seaweedfs-admin".ref}:/data"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-admin = {
              rule = "Host(`admin.trev.zip`)";
              middlewares = "secure-admin@file";
            };
          };
        };
        exec = [
          "admin"
          "-port=8080"
          "-masters=seaweedfs:9333"
          "-dataDir=/data"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs".ref;
        BindsTo = containers."seaweedfs".ref;
      };
    };

    volumes = {
      seaweedfs-admin = { };
    };
  };
}
