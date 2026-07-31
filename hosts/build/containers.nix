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
  forgejoRunner = {
    enable = true;
    url = "https://trev.zip/";
    name = "builder";
    inherit labels;
    capacity = 2;
    networks = [ "host" ];
    settings.container = {
      network = "host";
      privileged = true;
    };
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

    portainer-agent.enable = true;
  };
}
