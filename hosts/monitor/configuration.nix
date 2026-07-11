{ self, ... }:
{
  imports = [
    (self + /modules/nixos/profiles/homelab-lxc.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "grafana"
    "portainer/agent.nix"
    "traefik-kop"
    "victoria-logs"
    "victoria-metrics"
    "victoria-traces"
  ];

  home-manager.users.trev.imports = [
    (self + /modules/home-manager/profiles/trev/server.nix)
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.109";
  };
}
