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
        image = "docker.io/chrislusf/seaweedfs:4.17@sha256:186de7ef977a20343ee9a5544073f081976a29e2d29ecf8379891e7bf177fbe9";
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
