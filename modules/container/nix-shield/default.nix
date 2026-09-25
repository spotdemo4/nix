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
  cfg = config.trev.containers.nix-shield;
in
{
  options.trev.containers.nix-shield = {
    enable = mkEnableOption "nix-shield container";

    image = mkImageOption "trev.zip/llc/nix-shield:0.2.0@sha256:93f2f61d4f99386964afc99c9396331b22cbfa6621da3eda469a82fe79e5d814";

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
