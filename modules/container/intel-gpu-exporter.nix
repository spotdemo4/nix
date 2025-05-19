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
in {
  inherit (mkGpuExporter "card0");
  inherit (mkGpuExporter "card1");
}
