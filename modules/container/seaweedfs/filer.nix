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
        image = "docker.io/chrislusf/seaweedfs:4.19@sha256:90e181977effc58a303a1b21a0d581314e142b09543a712ff739c79ed78f42cf";
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
