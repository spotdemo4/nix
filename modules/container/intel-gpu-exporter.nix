{
  lib,
  config,
  ...
}:
{
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
    virtualisation.quadlet.containers."intel-gpu-exporter-${config.intel-gpu-exporter.card}".containerConfig =
      {
        image = "ghcr.io/spotdemo4/intel-gpu-exporter:latest@sha256:79b14da50f7db1e4143c10298fb234e55989f643180ee4a0d6b330f8f48b27f6";
        pull = "missing";
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
# This was a pain in the ass figuring out. Here are some crumbs for my future self
# https://github.com/blakeblackshear/frigate/discussions/5773#discussioncomment-12330162
# --privileged shouldn't be necessary here, and yet it is. Don't know what capabilities the container is missing,
# it works fine in the unprivileged LXC, but it being elevated here isn't really that big of a deal because it still can't hurt the host
