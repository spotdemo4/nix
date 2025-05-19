{
  config,
  self,
  ...
}: {
  virtualisation.oci-containers.containers = {
    portainer-agent = {
      image = "portainer/agent:latest";
      pull = "newer";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
        "/var/lib/containers/storage:/var/lib/docker/volumes"
      ];
      ports = [
        "9001:9001"
      ];
    };
  };
}
