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
        "10.10.10.109:19532:19532"
        "127.0.0.1:19532:19532"
        "10.10.10.109:9494:9494"
      ];
      extraArgs = [
        "--storage.received-at-retention"
        "24h"
        "--storage.maintenance-interval"
        "15m"
        "--storage.checkpoint-interval"
        "1h"
        "--storage.maintenance-timeout"
        "10m"
        "--storage.minimum-free-bytes"
        "53687091200"
      ];
    };
    json-exporter.enable = true;
    portainer-agent.enable = true;
    traefik-kop = {
      enable = true;
      ip = "10.10.10.109";
    };
    victoria-logs = {
      enable = true;
      extraArgs = [
        "-retentionPeriod=7d"
        "-retention.maxDiskSpaceUsageBytes=10GiB"
        "-storage.minFreeDiskSpaceBytes=10GiB"
      ];
    };
  };
}
