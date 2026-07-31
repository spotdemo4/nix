{
  config,
  self,
  ...
}:
let
  labels = [
    "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
    "ubuntu-24.04:docker://gitea/runner-images:ubuntu-24.04@sha256:58ea92624c7c09582e05594d95488331045053d3a3f34cf09649f2a32313a614"
    "nixos-latest:docker://nixos/nix:2.35.1@sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1"
  ];
  runner = {
    enable = true;
    name = "builder";
    inherit labels;
    capacity = 2;
    networks = [ "host" ];
    settings.container = {
      network = "host";
      privileged = true;
    };
  };
  forgejoRunner = runner // {
    url = "https://trev.zip/";
  };
in
{
  imports = [
    (self + /modules/container/forgejo-runner)
    (self + /modules/container/gitea-runner)
    (self + /modules/container/portainer-agent)
  ];

  trev.containers = {
    forgejo-runner = {
      enable = true;
      instances = {
        trev = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo".path;
        };
        org = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo-org".path;
        };
        template = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo-template".path;
        };
      };
    };

    gitea-runner = {
      enable = true;
      instances.quanta = runner // {
        url = "https://git.quantadev.cc/";
        tokenFile = config.age.secrets."quanta-runner".path;
      };
    };

    portainer-agent.enable = true;
  };
}
