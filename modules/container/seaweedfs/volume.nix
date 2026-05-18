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
        image = "docker.io/chrislusf/seaweedfs:4.26@sha256:cc1e3b75e57a3e1b9a698b9aaabd3fe54f4a43c315db457658d584599bd4b3cc";
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
