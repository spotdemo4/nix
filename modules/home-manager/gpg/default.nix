{
  config,
  lib,
  self,
  ...
}:
{
  options.trev.programs.gpg.enable = lib.mkEnableOption "Trev's GPG key provisioning";

  config = lib.mkIf config.trev.programs.gpg.enable {
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secrets."gpg" = {
        file = self + /secrets/gpg.age;
        path =
          config.home.homeDirectory
          + "/.gnupg/private-keys-v1.d/02F9D60E16452DC74C0FBFC2ECA9E20D1D75C89C.key";
        mode = "600";
      };
    };

    programs.gpg = {
      enable = true;
      publicKeys = [ { source = self + /secrets/gpg-public.asc; } ];
    };

    # importGpgKeys runs gpg, which spawns keyboxd. At boot there is no
    # /run/user/$UID yet, so its socket lands in ~/.gnupg and the daemon
    # lingers holding pubring.db's lock, deadlocking the session's keyboxd.
    home.activation.stopGpgKeyboxd = lib.hm.dag.entryAfter [ "importGpgKeys" ] ''
      run env GNUPGHOME=${lib.escapeShellArg config.programs.gpg.homedir} \
        ${config.programs.gpg.package}/bin/gpgconf --kill keyboxd
    '';
  };
}
