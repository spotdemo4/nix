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

    env = lib.mkOption {
      type = lib.types.str;
      description = "Environment variable mapping for the Podman secret.";
      default = "${name},type=env";
    };

    mount = lib.mkOption {
      type = lib.types.str;
      description = "Mount mapping for the Podman secret.";
      default = "${name},type=mount";
    };

    path = lib.mkOption {
      type = lib.types.str;
      description = "Path where the decrypted secret is mounted.";
      default = "/run/agenix/${name}";
    };
  };
}
