{
  lib,
  name,
  ...
}:
{
  options = {
    file = lib.mkOption {
      type = lib.types.str;
      description = "File path to the encrypted secret.";
    };

    ref = lib.mkOption {
      type = lib.types.str;
      description = "Podman secret reference name.";
      default = name;
    };

    path = lib.mkOption {
      type = lib.types.str;
      description = "Path where the decrypted secret is mounted.";
      default = "/run/agenix/${name}";
    };
  };
}
