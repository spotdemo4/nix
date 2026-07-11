{ self, ... }:
{
  imports = [
    (self + /modules/container/portainer-agent)
    (self + /modules/container/stalwart)
    (self + /modules/container/traefik-kop)
  ];

  trev.containers = {
    stalwart.enable = true;

    traefik-kop = {
      enable = true;
      ip = "10.10.10.112";
    };
  };
}
