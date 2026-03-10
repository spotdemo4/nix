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
            image = "docker.io/valkey/valkey:9.0.3-alpine@sha256:84c96f47ebe197e635cd3ddbe3ab74e8bdf783cf3befbfb1c36387275c1cd5d5";
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
