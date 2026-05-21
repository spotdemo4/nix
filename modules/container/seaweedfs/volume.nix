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
        image = "docker.io/chrislusf/seaweedfs:4.27@sha256:62521129b7f2a66f7f0b4e4be612736ff0989e9e502746f3dc42de4e7b54c9d8";
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
