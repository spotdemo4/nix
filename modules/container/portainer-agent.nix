{ ... }:
{
  virtualisation.quadlet.containers.portainer-agent = {
    containerConfig = {
      image = "docker.io/portainer/agent:2.37.0@sha256:bbe36b101908e18fec147d2fb833ea7ecfbc9021a08566c8ae0772029ca2eed8";
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
