{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes networks;
in
{
  imports = [
    ./admin.nix
    ./filer.nix
    ./s3.nix
    ./volume.nix
  ];

  virtualisation.quadlet = {
    containers.seaweedfs.containerConfig = {
      image = "docker.io/chrislusf/seaweedfs:4.05@sha256:295b8f7bd2209afdf5b3fe5bc3a2ca8a72747365fe111b4de412511aa9f56e99";
      pull = "missing";
      publishPorts = [
        "8080"
      ];
      networks = [
        networks."seaweedfs".ref
      ];
      volumes = [
        "${volumes."seaweedfs".ref}:/data"
      ];
      exec = [
        "master"
        "-port=8080"
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
