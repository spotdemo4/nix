{
  lib,
  config,
  ...
}: {
  options.intel-gpu-exporter = {
    enable = lib.mkEnableOption "enable intel gpu exporter";

    card = lib.mkOption {
      type = lib.types.str;
      default = "card0";
      description = ''
        The /dev/dri name for the card
      '';
    };

    render = lib.mkOption {
      type = lib.types.str;
      default = "renderD128";
      description = ''
        The /dev/dri render file for the card
      '';
    };
  };

  config = lib.mkIf config.update.enable {
    virtualisation.quadlet.containers."intel-gpu-exporter-${config.intel-gpu-exporter.card}".containerConfig = {
      image = "ghcr.io/spotdemo4/intel-gpu-exporter:latest";
      pull = "newer";
      autoUpdate = "registry";
      environments = {
        DEVICE = "drm:/dev/dri/${config.intel-gpu-exporter.card}";
      };
      publishPorts = [
        "8080:8080"
      ];
      devices = [
        "/dev/dri/${config.intel-gpu-exporter.card}:/dev/dri/${config.intel-gpu-exporter.card}"
        "/dev/dri/${config.intel-gpu-exporter.render}:/dev/dri/${config.intel-gpu-exporter.render}"
      ];
      addCapabilities = [
        "CAP_PERFMON"
      ];
      podmanArgs = [
        "--privileged"
      ];
    };
  };
}
