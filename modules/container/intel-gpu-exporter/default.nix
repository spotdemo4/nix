{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.intel-gpu-exporter;
in
{
  options.trev.containers.intel-gpu-exporter = {
    enable = mkEnableOption "the Intel GPU Exporter container";
    image = containerOptions.mkImageOption "ghcr.io/spotdemo4/intel-gpu-exporter:latest@sha256:79b14da50f7db1e4143c10298fb234e55989f643180ee4a0d6b330f8f48b27f6";

    publishPorts = mkOption {
      type = types.listOf types.str;
      default = [ "8080:8080" ];
      description = "Ports to publish from Intel GPU Exporter.";
    };

    card = mkOption {
      type = types.str;
      default = "card0";
      description = ''
        The /dev/dri name for the card
      '';
    };

    render = mkOption {
      type = types.str;
      default = "renderD128";
      description = ''
        The /dev/dri render file for the card
      '';
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet.containers."intel-gpu-exporter-${cfg.card}".containerConfig = {
      image = cfg.image;
      pull = "missing";
      environments = {
        DEVICE = "drm:/dev/dri/${cfg.card}";
      };
      publishPorts = cfg.publishPorts;
      devices = [
        "/dev/dri/${cfg.card}:/dev/dri/${cfg.card}"
        "/dev/dri/${cfg.render}:/dev/dri/${cfg.render}"
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
