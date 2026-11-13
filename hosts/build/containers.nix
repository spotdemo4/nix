{
  config,
  lib,
  self,
  ...
}:
let
  labels = import (self + /lib/forgejo-runner/labels.nix) { inherit lib; };
  runner = {
    enable = true;
    name = "builder";
    labels = labels.gitea;
    capacity = 2;
    networks = [ "host" ];
    settings.container = {
      network = "host";
      privileged = true;
    };
  };
  forgejoRunner = runner // {
    url = "https://trev.zip/";
    capacity = 4;
    labels = labels.forgejo;
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
        quanta = forgejoRunner // {
          tokenFile = config.age.secrets."forgejo-quanta".path;
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
