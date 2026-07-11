{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.cobalt-youtube;
  gluetunConfig = lib.attrByPath [ "trev" "containers" "gluetun" ] {
    enable = false;
    instances = { };
  } config;
  gluetun = lib.attrByPath [ "instances" "cobalt" ] {
    enable = false;
    ref = "gluetun-cobalt";
  } gluetunConfig;
in
{
  options.trev.containers.cobalt-youtube = {
    enable = mkEnableOption "Cobalt YouTube session generator container";

    image = containerOptions.mkImageOption "ghcr.io/imputnet/yt-session-generator:webserver@sha256:95b801ce70c93dfa7a0732fa52d41ef0fe891489e72926360bd50aa001797d5d";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = gluetunConfig.enable && gluetun.enable;
        message = "trev.containers.cobalt-youtube requires trev.containers.gluetun.enable = true and trev.containers.gluetun.instances.cobalt.enable = true";
      }
    ];

    virtualisation.quadlet.containers.cobalt-youtube.containerConfig = {
      image = cfg.image;
      pull = "missing";
      networks = [
        "container:${gluetun.ref}"
      ];
    };
  };
}
