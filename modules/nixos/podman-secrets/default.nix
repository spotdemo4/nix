{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.podman-secrets;
in
{
  options = {
    trev.podman-secrets.enable = lib.mkEnableOption "Podman secrets backed by agenix";

    secrets = lib.mkOption {
      default = { };
      description = "Secrets to decrypt with agenix and register with Podman.";
      type = lib.types.attrsOf (lib.types.submodule (import (self + /lib/secrets/secret.nix)));
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = lib.mapAttrs (_: secret: { inherit (secret) file; }) config.secrets;

    system.activationScripts = lib.mapAttrs (name: _: ''
      ${pkgs.podman}/bin/podman secret create --replace=true ${lib.escapeShellArg name} ${
        lib.escapeShellArg config.age.secrets.${name}.path
      }
    '') config.secrets;
  };
}
