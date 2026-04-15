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
        image = "docker.io/chrislusf/seaweedfs:4.20@sha256:cea8339d21dad1b200adce581dd7434d254b8f5975f142c3b4c930ba78647eef";
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
