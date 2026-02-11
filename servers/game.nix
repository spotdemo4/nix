{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "minecraft"
    "portainer/agent.nix"
    "satisfactory"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.111";
  };
}
