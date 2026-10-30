{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    ;
  cfg = config.trev.containers.solid-toast;
in
{
  options.trev.containers.solid-toast = {
    enable = mkEnableOption "solid-toast example container";

    image = mkImageOption "trev.zip/llc/solid-toast/example:1.2.8@sha256:c781a81e9fb241d58159d849b4df395650364fb91921835118b23f2c2ab569f1";

    domain = mkOption {
      type = types.str;
      default = "solid-toast.trev.zip";
      description = "Domain routed to the solid-toast example.";
    };

    port = mkOption {
      type = types.port;
      default = 3001;
      description = "solid-toast port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.solid-toast = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    virtualisation.quadlet.containers.solid-toast.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      publishPorts = [ "${toString cfg.port}:3000" ];
    };
  };
}
