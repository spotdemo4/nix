{
  config,
  self,
  ...
}:
{
  age.secrets."gpg".file = self + /secrets/gpg.age;
  age.secrets."gpg".path =
    config.home.homeDirectory
    + "/.gnupg/private-keys-v1.d/02F9D60E16452DC74C0FBFC2ECA9E20D1D75C89C.key";
  age.secrets."gpg".mode = "600";
}
