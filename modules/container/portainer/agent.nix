{ ... }:
{
  virtualisation.quadlet.containers.portainer-agent = {
    containerConfig = {
      image = "docker.io/portainer/agent:2.42.0@sha256:d67c13e489907f6ccf63ba22562910cdd143f788671038f1b10728f8bb7f9385";
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
