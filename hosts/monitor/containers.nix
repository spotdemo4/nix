{ self, ... }:
{
  imports = [
    (self + /modules/container/grafana)
    (self + /modules/container/json-exporter)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/traefik-kop)
    (self + /modules/container/victoria-logs)
    (self + /modules/container/victoria-metrics)
    (self + /modules/container/victoria-traces)
  ];

  trev.containers = {
    grafana.enable = true;
    json-exporter.enable = true;
    portainer-agent.enable = true;
    traefik-kop = {
      enable = true;
      ip = "10.10.10.109";
    };
    victoria-logs.enable = true;
    victoria-metrics.enable = true;
    victoria-traces.enable = true;
  };
}
