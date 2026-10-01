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

    image = mkImageOption "trev.zip/llc/solid-toast/example:1.1.2@sha256:5a975181cefb1cc37f3b78b4d6f4c2e3b2bfa33fd1f04ffd70913e6f664453a5";

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
