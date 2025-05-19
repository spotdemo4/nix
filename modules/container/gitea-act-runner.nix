{
  config,
  self,
  ...
}: {
  age.secrets."gitea-runner".file = self + /secrets/gitea-runner.age;

  virtualisation.oci-containers.containers = {
    gitea-act-runner = {
      image = "gitea/act_runner:nightly";
      pull = "newer";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
      environment = {
        GITEA_INSTANCE_URL = "https://git.quantadev.cc";
      };
      environmentFiles = [
        config.age.secrets."gitea-runner".path
      ];
    };
  };
}
