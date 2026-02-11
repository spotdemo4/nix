{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers volumes networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.seaweedfs-filer = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.12@sha256:d7f3fdf6fb9c9375551e95bc985abae74a157789d868341e9e84a999ed8ea21c";
        pull = "missing";
        publishPorts = [
          "8888"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        volumes = [
          "${./filer.toml}:/etc/seaweedfs/filer.toml"
          "${volumes."seaweedfs-filer".ref}:/data"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-filer = {
              rule = "Host(`filer.trev.zip`)";
              middlewares = "secure-trev@file";
            };
          };
        };
        exec = [
          "filer"
          "-master=seaweedfs:9333"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs".ref;
        BindsTo = containers."seaweedfs".ref;
      };
    };

    volumes = {
      seaweedfs-filer = { };
    };
  };
}
