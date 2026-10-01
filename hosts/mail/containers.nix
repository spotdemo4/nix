{ self, ... }:
{
  imports = [
    (self + /modules/container/portainer-agent)
    (self + /modules/container/stalwart)
  ];

  trev.containers = {
    stalwart.enable = true;
  };
}
