{ self, ... }:
{
  imports = [
    (self + /modules/container/minecraft)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/traefik-kop)
  ];

  trev.containers = {
    minecraft = {
      enable = true;
      volumeName = "allthemods10_3";
    };
    portainer-agent.enable = true;
    traefik-kop = {
      enable = true;
      ip = "10.10.10.111";
    };
  };
}
