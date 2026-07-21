{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  secrets = config.virtualisation.quadlet.secrets;
  secretsWithFiles = lib.filterAttrs (_: secret: secret.file != null) secrets;
  secretsWithoutFiles = lib.attrNames (lib.filterAttrs (_: secret: secret.file == null) secrets);
  secretRefs = map (secret: secret.ref) (lib.attrValues secrets);
  duplicateSecretRefs = lib.unique (
    builtins.filter (
      ref: builtins.length (builtins.filter (candidate: candidate == ref) secretRefs) > 1
    ) secretRefs
  );
in
{
  options.virtualisation.quadlet.secrets = lib.mkOption {
    default = { };
    description = "Secrets to decrypt with agenix and register with Podman.";
    type = lib.types.attrsOf (lib.types.submodule (import (self + /lib/secrets/secret.nix)));
  };

  config = lib.mkIf (secrets != { }) {
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
