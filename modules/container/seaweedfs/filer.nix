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
        image = "docker.io/chrislusf/seaweedfs:4.09@sha256:353c69c8ddd7e13c85c1290dca9d1690bf3d066237b7ede7920b8fd2864858e7";
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
