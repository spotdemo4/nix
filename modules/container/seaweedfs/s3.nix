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
        image = "docker.io/chrislusf/seaweedfs:4.16@sha256:8550d861c9383b5db177f725e58775f036323c4adb2c335a2346dddc7da75e5e";
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
