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
    containers.seaweedfs-ssd = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.09@sha256:353c69c8ddd7e13c85c1290dca9d1690bf3d066237b7ede7920b8fd2864858e7";
        pull = "missing";
        publishPorts = [
          "8080"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        volumes = [
          "/mnt/seaweed:/data"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-ssd = {
              rule = "Host(`ssd.trev.zip`)";
              middlewares = "secure-trev@file";
            };
          };
        };
        exec = [
          "volume"
          "-master=seaweedfs:9333"
          "-dir=/data"
          "-max=8"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs".ref;
        BindsTo = containers."seaweedfs".ref;
      };
    };
  };
}
