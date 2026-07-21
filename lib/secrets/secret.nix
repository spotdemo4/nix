{
  lib,
  name,
  ...
}:
{
  options = {
    file = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
      default = null;
      description = "Optional source file for the secret.";
    };

    ref = lib.mkOption {
      type = lib.types.str;
      description = "Podman secret reference name.";
      default = name;
    };
  };
}
