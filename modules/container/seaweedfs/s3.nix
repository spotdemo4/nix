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
        image = "docker.io/chrislusf/seaweedfs:4.21@sha256:e0b528145ea514040ab00d03ff0833f56acb1f0e07aeab232e20485af9278fd8";
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
