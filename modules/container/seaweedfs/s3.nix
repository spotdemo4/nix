{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.seaweedfs-s3 = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.09@sha256:353c69c8ddd7e13c85c1290dca9d1690bf3d066237b7ede7920b8fd2864858e7";
        pull = "missing";
        publishPorts = [
          "8333"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-s3 = {
              rule = "Host(`s3.trev.zip`)";
              middlewares = "secure@file";
            };
          };
        };
        exec = [
          "s3"
          "-filer=seaweedfs-filer:8888"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs-filer".ref;
        BindsTo = containers."seaweedfs-filer".ref;
      };
    };
  };
}
