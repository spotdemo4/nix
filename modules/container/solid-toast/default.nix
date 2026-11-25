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

    image = mkImageOption "trev.zip/llc/solid-toast/example:1.2.15@sha256:4fb3577ee5454ac0bd6a274ac3ffdcb80b97e0abc7fe7e1c083fe90316f8b421";

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
