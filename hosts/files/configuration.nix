{ self, ... }:
{
  imports = [
    (self + /templates/lxc)
    ./hardware-configuration.nix
  ]
  ++ map (c: self + /modules/container/${c}) [
    "copyparty"
    "forgejo"
    "garage"
    "immich"
    "niks3"
    "portainer/agent.nix"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.113";
  };
}
