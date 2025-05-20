{lib, ...}: let
  mkGpuExporter = name: {
    virtualisation.oci-containers.containers = {
      "intel-gpu-exporter-${name}" = {
        image = "ghcr.io/spotdemo4/intel-gpu-exporter:latest";
        pull = "newer";
        privileged = true;
        devices = [
          "/dev/dri/${name}:/dev/dri/${name}"
        ];
        environment = {
          DEVICE = "drm:/dev/dri/${name}";
        };
        networks = [
          "victoria-metrics"
        ];
        capabilities = {
          "CAP_PERFMON" = true;
        };
      };
    };
  };

  card0 = mkGpuExporter "card0";
  card1 = mkGpuExporter "card1";
in
  lib.recursiveUpdate card0 card1
