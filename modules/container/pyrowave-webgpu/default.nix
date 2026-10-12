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
  cfg = config.trev.containers.pyrowave-webgpu;
in
{
  options.trev.containers.pyrowave-webgpu = {
    enable = mkEnableOption "pyrowave-webgpu demo container";

    image = mkImageOption "trev.zip/llc/pyrowave-webgpu/demo:0.2.0@sha256:fc07e10f5619214d2ff47492b7a8d2072656e268657c992dd08954a27fee8a54";

    domain = mkOption {
      type = types.str;
      default = "pyrowave-webgpu.trev.zip";
      description = "Domain routed to the pyrowave-webgpu demo.";
    };

    port = mkOption {
      type = types.port;
      default = 3002;
      description = "pyrowave-webgpu port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.pyrowave-webgpu = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    virtualisation.quadlet.containers.pyrowave-webgpu.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      publishPorts = [ "${toString cfg.port}:3000" ];
    };
  };
}
