{ self, ... }:
{
  imports = [ (self + /modules/container/portainer-agent) ];

  trev.containers.portainer-agent.enable = true;
}
