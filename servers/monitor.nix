{ self, ... }:
{
  imports = [
    (self + /hosts/lxc/configuration.nix)
  ]
  ++ map (c: self + /modules/container/${c}) [
    "grafana"
    "portainer/agent.nix"
    "traefik-kop"
    "victoria-logs"
    "victoria-metrics"
    "victoria-traces"
  ];

  # mapping to gateway
  traefik-kop = {
    enable = true;
    ip = "10.10.10.109";
  };
}
