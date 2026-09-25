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

    image = mkImageOption "trev.zip/llc/nix-shield:0.4.0@sha256:1c4a340f07527f5bcb5c657761dc2650d24e15a6e7167f82e3cc30a72c9c93ac";

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
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet.containers.nix-shield.containerConfig = mkContainer {
      image = cfg.image;
      pull = "missing";
      publishPorts = [ "3000" ];
      environments.NIX_SHIELD_ALLOWED_IPS = concatStringsSep "," cfg.allowedIPs;
      labels = {
        traefik = {
          enable = true;
          http.routers.nix-shield = {
            rule = "Host(`${cfg.domain}`)";
            middlewares = "secure@file";
          };
        };
      };
    };
  };
}
