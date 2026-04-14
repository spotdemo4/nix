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
        image = "docker.io/chrislusf/seaweedfs:4.20@sha256:0d763e554fa570988a65430dae014eac343d05777e10b3607977c234bc602c46";
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
