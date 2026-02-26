{ ... }:
{
  virtualisation.quadlet.containers.portainer-agent = {
    containerConfig = {
      image = "docker.io/portainer/agent:2.39.0@sha256:e3a9bcb1e5862edaca62d6e54f70efc5815dff33e955a30578b174423b19977c";
      pull = "missing";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
        "/var/lib/containers/storage:/var/lib/docker/volumes"
      ];
      publishPorts = [
        "9001:9001"
      ];
    };

    unitConfig = {
      After = "podman.socket";
      BindsTo = "podman.socket";
      ReloadPropagatedFrom = "podman.socket";
    };
  };
}
