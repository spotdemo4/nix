{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    ./json-exporter.nix
  ];

  virtualisation.quadlet = {
    containers.victoria-metrics.containerConfig = {
      image = "docker.io/victoriametrics/victoria-metrics:v1.135.0@sha256:647f1a19274a362692c0968b926f4acecfdac9488bbf70f1985925d1717063b5";
      pull = "missing";
      volumes = [
        "${volumes."victoria-metrics".ref}:/victoria-metrics-data"
        "${./prometheus.yaml}:/prometheus.yaml"
      ];
      publishPorts = [
        "8428:8428"
      ];
      networks = [
        networks."victoria-metrics".ref
      ];
      exec = [
        "--selfScrapeInterval=5s"
        "-storageDataPath=victoria-metrics-data"
        "-promscrape.config=prometheus.yaml"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.victoria-metrics = {
            rule = "Host(`metrics.trev.xyz`)";
            middlewares = "secure-trev@file";
          };
        };
      };
    };

    networks = {
      victoria-metrics = { };
    };

    volumes = {
      victoria-metrics = { };
    };
  };
}
