{
  lib,
  config,
  ...
}:
with lib;
{
  options.valkey = mkOption {
    default = { };
    description = "valkey container configuration";

    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            publish = mkOption {
              type = types.bool;
              default = false;
            };

            networks = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };

            args = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };

            ref = mkOption {
              type = types.str;
              default = "valkey-${name}";
            };
          };
        }
      )
    );
  };

  config = mkIf (config.valkey != { }) {
    virtualisation.quadlet = {
      containers = mapAttrs' (
        name: opts:
        nameValuePair "valkey-${name}" {
          containerConfig = {
            image = "docker.io/valkey/valkey:9.0.2-alpine@sha256:68677f85c863830af7836ff07c4a13b7f085ebeff62f4dedb71499ca27d229f2";
            pull = "missing";
            healthCmd = "valkey-cli PING";
            notify = "healthy";
            publishPorts = mkIf opts.publish [ "6379:6379" ];
            networks = opts.networks;
            environments = {
              VALKEY_EXTRA_FLAGS = builtins.concatStringsSep " " opts.args;
            };
          };
        }
      ) config.valkey;
    };
  };
}
