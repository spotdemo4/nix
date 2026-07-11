{ self, ... }:
{
  imports = [
    (self + /modules/container/portainer-agent)
    (self + /modules/container/traefik-kop)
  ];

  trev.containers = {
    portainer-agent.enable = true;
    traefik-kop = {
      enable = true;
      ip = "10.10.10.111";
    };
  };
}
