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
    containers.seaweedfs-admin = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.19@sha256:90e181977effc58a303a1b21a0d581314e142b09543a712ff739c79ed78f42cf";
        pull = "missing";
        publishPorts = [
          "8080"
        ];
        networks = [
          networks."seaweedfs".ref
        ];
        volumes = [
          "${volumes."seaweedfs-admin".ref}:/data"
        ];
        labels = toLabel {
          attrs.traefik = {
            enable = true;
            http.routers.seaweedfs-admin = {
              rule = "Host(`admin.trev.zip`)";
              middlewares = "secure-admin@file";
            };
          };
        };
        exec = [
          "admin"
          "-port=8080"
          "-masters=seaweedfs:9333"
          "-dataDir=/data"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs".ref;
        BindsTo = containers."seaweedfs".ref;
      };
    };

    volumes = {
      seaweedfs-admin = { };
    };
  };
}
