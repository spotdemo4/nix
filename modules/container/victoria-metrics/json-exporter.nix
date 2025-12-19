{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
in
{
  virtualisation.quadlet = {
    containers.json-exporter.containerConfig = {
      image = "quay.io/prometheuscommunity/json-exporter:v0.7.0@sha256:3a777171d39ad435cb39519e84e0a8b5c63c7e716cc06011f8140cfaabfc1baf";
      pull = "missing";
      volumes = [
        "${./json-exporter.yaml}:/json-exporter.yaml"
      ];
      networks = [
        networks."victoria-metrics".ref
      ];
      exec = [
        "--config.file=/json-exporter.yaml"
      ];
    };
  };
}
