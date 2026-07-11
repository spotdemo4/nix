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
  };
}
