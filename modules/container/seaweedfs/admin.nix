{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes networks;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.seaweedfs-admin.containerConfig = {
      image = "docker.io/chrislusf/seaweedfs:4.05@sha256:295b8f7bd2209afdf5b3fe5bc3a2ca8a72747365fe111b4de412511aa9f56e99";
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

    volumes = {
      seaweedfs-admin = { };
    };
  };
}
