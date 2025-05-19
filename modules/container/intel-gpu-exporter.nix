{...}: let
  mkGpuExporter = name: {
    virtualisation.oci-containers.containers = {
      "intel-gpu-exporter-${name}" = {
        image = "ghcr.io/spotdemo4/intel-gpu-exporter:latest";
        pull = "newer";
        devices = [
          "/dev/dri:/dev/dri"
        ];
        environment = {
          DEVICE = "drm:/dev/dri/${name}";
        };
        networks = [
          "prometheus"
        ];
      };
    };
  };

  card0 = mkGpuExporter "card0";
  card1 = mkGpuExporter "card1";
in
  card0 // card1
