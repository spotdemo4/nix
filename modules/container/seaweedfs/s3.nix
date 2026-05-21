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
        image = "docker.io/chrislusf/seaweedfs:4.27@sha256:62521129b7f2a66f7f0b4e4be612736ff0989e9e502746f3dc42de4e7b54c9d8";
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
