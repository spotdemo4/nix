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
        image = "docker.io/chrislusf/seaweedfs:4.22@sha256:dc40601b7a598dbaa0312e4aadf1cc239de2ed6a177babd2f181a6d766a20dd6";
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
