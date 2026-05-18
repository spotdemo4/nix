{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) containers networks;
in
{
  virtualisation.quadlet = {
    containers.seaweedfs-worker = {
      containerConfig = {
        image = "docker.io/chrislusf/seaweedfs:4.26@sha256:cc1e3b75e57a3e1b9a698b9aaabd3fe54f4a43c315db457658d584599bd4b3cc";
        pull = "missing";
        networks = [
          networks."seaweedfs".ref
        ];
        exec = [
          "worker"
          "-admin=seaweedfs-admin:8080"
          "-capabilities=vacuum,ec,replication"
        ];
      };

      unitConfig = {
        After = containers."seaweedfs-admin".ref;
        BindsTo = containers."seaweedfs-admin".ref;
      };
    };
  };
}
