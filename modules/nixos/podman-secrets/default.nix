{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.trev.podman-secrets;
  secretsWithFiles = lib.filterAttrs (_: secret: secret.file != null) config.secrets;
  secretsWithoutFiles = lib.attrNames (
    lib.filterAttrs (_: secret: secret.file == null) config.secrets
  );
  secretRefs = map (secret: secret.ref) (lib.attrValues config.secrets);
  duplicateSecretRefs = lib.unique (
    builtins.filter (
      ref: builtins.length (builtins.filter (candidate: candidate == ref) secretRefs) > 1
    ) secretRefs
  );
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
    assertions = [
      {
        assertion = secretsWithoutFiles == [ ];
        message = "Podman secrets require source files: ${lib.concatStringsSep ", " secretsWithoutFiles}";
      }
      {
        assertion = duplicateSecretRefs == [ ];
        message = "Podman secret references must be unique: ${lib.concatStringsSep ", " duplicateSecretRefs}";
      }
    ];

    age.secrets = lib.mapAttrs (_: secret: { inherit (secret) file; }) secretsWithFiles;

    system.activationScripts = lib.mapAttrs (name: secret: ''
      ${pkgs.podman}/bin/podman secret create --replace=true ${lib.escapeShellArg secret.ref} ${
        lib.escapeShellArg config.age.secrets.${name}.path
      }
    '') secretsWithFiles;
  };
}
