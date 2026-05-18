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
      image = "docker.io/chrislusf/seaweedfs:4.26@sha256:cc1e3b75e57a3e1b9a698b9aaabd3fe54f4a43c315db457658d584599bd4b3cc";
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
