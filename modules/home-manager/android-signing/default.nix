{
  config,
  lib,
  self,
  ...
}:
{
  options.trev.programs.android-signing.enable =
    lib.mkEnableOption "Trev's Android release signing keystore";

  # a PKCS#12 keystore holding one key, with the alias release, and the password of both
  config = lib.mkIf config.trev.programs.android-signing.enable {
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secrets = {
        android-keystore = {
          file = self + /secrets/android-keystore.age;
          mode = "400";
        };
        android-keystore-password = {
          file = self + /secrets/android-keystore-password.age;
          mode = "400";
        };
      };
    };
  };
}
