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
        image = "docker.io/chrislusf/seaweedfs:4.22@sha256:84429e5f21fad82246f5cfae7b39e9a17da18afb62f2b79c25ccd364ab02793b";
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
