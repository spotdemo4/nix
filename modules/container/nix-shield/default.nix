{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkContainer
    mkImageOption
    ;
  cfg = config.trev.containers.nix-shield;
in
{
  options.trev.containers.nix-shield = {
    enable = mkEnableOption "nix-shield container";

    image = mkImageOption "trev.zip/llc/nix-shield:0.4.2@sha256:bdb84cd1388a593ce791e7f50ebaf7cd5c3805963da2848808e65180389cb6cc";

    allowedIPs = mkOption {
      type = types.listOf types.str;
      default = [ "10.10.10.105" ];
      description = "IP addresses nix-shield is allowed to fetch from in addition to public addresses.";
    };

    domain = mkOption {
      type = types.str;
      default = "nix-shield.trev.zip";
      description = "Domain routed to nix-shield.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "nix-shield port published on the host.";
    };
  };

  config = mkIf cfg.enable {
    trev.proxy.routes.nix-shield = {
      domains = [ cfg.domain ];
      inherit (cfg) port;
    };

    virtualisation.quadlet.containers.nix-shield.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      publishPorts = [ "${toString cfg.port}:3000" ];
      environments.NIX_SHIELD_ALLOWED_IPS = concatStringsSep "," cfg.allowedIPs;
    };
  };
}
