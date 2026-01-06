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
        image = "docker.io/chrislusf/seaweedfs:4.05@sha256:295b8f7bd2209afdf5b3fe5bc3a2ca8a72747365fe111b4de412511aa9f56e99";
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
