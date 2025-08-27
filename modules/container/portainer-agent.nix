{...}: {
  virtualisation.quadlet.containers.portainer-agent = {
    containerConfig = {
      image = "docker.io/portainer/agent:2.33.1@sha256:2c8e3aea83e1eb47ce14616fdff2b2193a53edc325522e6180463672868e9fe0";
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
