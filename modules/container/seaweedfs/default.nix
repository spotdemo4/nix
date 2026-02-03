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
      image = "docker.io/chrislusf/seaweedfs:4.08@sha256:8779e14fbb8c76c607bc2ed934aeeb61e5319016f0ac1ba4667eae8f40fe623b";
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
