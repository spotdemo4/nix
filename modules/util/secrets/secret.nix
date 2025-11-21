{
  lib,
  name,
  config,
  ...
}:
# https://docs.podman.io/en/stable/markdown/podman-run.1.html#secret-secret-opt-opt
with lib;
{
  options = {
    file = mkOption {
      type = types.str;
      description = ''
        File path to the secret
      '';
    };

    ref = mkOption {
      type = types.str;
      description = ''
        Reference name for the secret
      '';
      default = name;
    };

    env = mkOption {
      type = types.str;
      description = ''
        Environment variable mapping for the secret in the format:
        name,type=env
      '';
      default = "${name},type=env";
    };

    mount = mkOption {
      type = types.str;
      description = ''
        Mount mapping for the secret in the format:
        name,type=mount
      '';
      default = "${name},type=mount";
    };

    path = mkOption {
      type = types.str;
      description = ''
        Path where the decrypted secret will be mounted
      '';
      default = config.age.secrets."${name}".path;
    };
  };
}
