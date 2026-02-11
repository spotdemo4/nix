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
  imports = [
    ./admin.nix
    ./filer.nix
    ./s3.nix
    ./volume.nix
    ./worker.nix
  ];

  virtualisation.quadlet = {
    containers.seaweedfs.containerConfig = {
      image = "docker.io/chrislusf/seaweedfs:4.12@sha256:d7f3fdf6fb9c9375551e95bc985abae74a157789d868341e9e84a999ed8ea21c";
      pull = "missing";
      publishPorts = [
        "9333"
      ];
      networks = [
        networks."seaweedfs".ref
      ];
      volumes = [
        "${volumes."seaweedfs".ref}:/data"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.seaweedfs = {
            rule = "Host(`seaweedfs.trev.zip`)";
            middlewares = "secure-trev@file";
          };
        };
      };
      exec = [
        "master"
        "-ip=seaweedfs"
        "-mdir=/data"
      ];
    };

    networks = {
      seaweedfs = { };
    };

    volumes = {
      seaweedfs = { };
    };
  };
}
