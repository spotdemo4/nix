{ ... }:
{
  virtualisation.quadlet.containers.portainer-agent = {
    containerConfig = {
      image = "docker.io/portainer/agent:2.39.1@sha256:7af856876dcb2778108bf6846f3da31b176443db90e3de31fcfdf17e5ab7857e";
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
