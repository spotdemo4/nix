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
      # Registered instance-wide, so it takes jobs from every user and organization
      instances.global = runner // {
        url = "https://trev.zip/";
        tokenFile = config.age.secrets."forgejo-runner".path;
        capacity = 4;
        labels = labels.forgejo;
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
