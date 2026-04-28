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
      image = "docker.io/chrislusf/seaweedfs:4.22@sha256:dc40601b7a598dbaa0312e4aadf1cc239de2ed6a177babd2f181a6d766a20dd6";
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
