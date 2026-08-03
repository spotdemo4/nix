{ self, ... }:
{
  imports = [
    (self + /modules/container/duckmetrics)
    (self + /modules/container/json-exporter)
    (self + /modules/container/portainer-agent)
    (self + /modules/container/traefik-kop)
    (self + /modules/container/victoria-logs)
  ];

  trev.containers = {
    duckmetrics = {
      enable = true;
      publishPorts = [
        "10.10.10.109:8080:8080"
        "10.10.10.109:4317:4317"
        "10.10.10.109:4318:4318"
      ];
    };
    json-exporter.enable = true;
    portainer-agent.enable = true;
    traefik-kop = {
      enable = true;
      ip = "10.10.10.109";
    };
    victoria-logs.enable = true;
  };
}
