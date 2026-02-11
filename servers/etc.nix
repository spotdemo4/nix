{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "anubis"
    "cobalt"
    "crowdsec"
    "discord-openrouter"
    "portainer/agent.nix"
    "shlink"
    "traefik-kop"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.114";
  };
}
