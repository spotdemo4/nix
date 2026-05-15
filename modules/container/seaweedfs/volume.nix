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
        image = "docker.io/chrislusf/seaweedfs:4.25@sha256:c42a5268ca13fcb65e0fae925886b107f4bf294d8db15e1be5509d55104eb509";
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
