{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    ./admin.nix
  ];

  virtualisation.quadlet = {
    containers.seaweedfs.containerConfig = {
      image = "docker.io/chrislusf/seaweedfs:4.05@sha256:295b8f7bd2209afdf5b3fe5bc3a2ca8a72747365fe111b4de412511aa9f56e99";
      pull = "missing";
      publishPorts = [
        # "9333" # master
        # "8080" # volume
        # "8888" # filer
        "8333" # s3
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
          http.routers.seaweedfs-s3 = {
            rule = "Host(`s3.trev.zip`)";
            middlewares = "secure@file";
          };
        };
      };
      exec = [
        "server"
        "-ip=seaweedfs"
        "-dir=/data"
        "-filer"
        "-s3"
      ];
    };

    networks = {
      seaweedfs = { };
    };
  };
}
