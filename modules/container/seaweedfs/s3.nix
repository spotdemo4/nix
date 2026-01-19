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
        image = "docker.io/chrislusf/seaweedfs:4.07@sha256:10fa7df90911dd83439f4d3d792a1c5c6c630121cb2094ba209f42d4b0ca975d";
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
