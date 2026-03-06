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
        image = "docker.io/chrislusf/seaweedfs:4.15@sha256:1593bd2a98964f5d4df83fa7db2b3d4ee7b20190813cc5bf8c3200e0e70d346e";
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
