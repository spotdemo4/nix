{
  config,
  self,
  ...
}: {
  age.secrets."gitea-runner".file = self + /secrets/gitea-runner.age;

  virtualisation.oci-containers.containers = {
    gitea-act-runner = {
      image = "gitea/act_runner:nightly";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
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
