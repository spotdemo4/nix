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
    containers.seaweedfs-filer = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.05@sha256:295b8f7bd2209afdf5b3fe5bc3a2ca8a72747365fe111b4de412511aa9f56e99";
        pull = "missing";
        publishPorts = [
          "8888"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        volumes = [
          "${./filer.toml}:/etc/seaweedfs/filer.toml"
          "${volumes."seaweedfs-filer".ref}:/data"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-filer = {
              rule = "Host(`filer.trev.zip`)";
              middlewares = "secure-trev@file";
            };
          };
        };
        exec = [
          "filer"
          "-master=seaweedfs:9333"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs".ref;
        BindsTo = containers."seaweedfs".ref;
      };
    };

    volumes = {
      seaweedfs-filer = { };
    };
  };
}
