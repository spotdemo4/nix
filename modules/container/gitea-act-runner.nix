{
  config,
  self,
  ...
}: {
  age.secrets."gitea-runner".file = self + /secrets/gitea-runner.age;

  virtualisation.quadlet.containers.gitea-act-runner = {
    containerConfig = {
      image = "docker.io/gitea/act_runner:nightly";
      pull = "newer";
      autoUpdate = "registry";
      environments = {
        GITEA_INSTANCE_URL = "https://git.quantadev.cc";
      };
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
      environmentFiles = [
        config.age.secrets."gitea-runner".path
      ];
    };

    unitConfig = {
      After = "podman.socket";
      BindsTo = "podman.socket";
      ReloadPropagatedFrom = "podman.socket";
    };
  };
}
