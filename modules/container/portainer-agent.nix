{...}: {
  virtualisation.quadlet.containers.portainer-agent.containerConfig = {
    image = "portainer/agent:latest";
    pull = "newer";
    autoUpdate = "registry";
    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock"
      "/var/lib/containers/storage:/var/lib/docker/volumes"
    ];
    publishPorts = [
      "9001:9001"
    ];
  };
}
