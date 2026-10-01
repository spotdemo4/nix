{ self, ... }:
{
  imports = [
    (self + /modules/container/minecraft)
    (self + /modules/container/portainer-agent)
  ];

  trev.containers = {
    minecraft = {
      enable = true;
      volumeName = "allthemods10_3";
    };
    portainer-agent.enable = true;
  };
}
