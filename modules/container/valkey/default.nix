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
            networks = mkOption {
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
            image = "docker.io/valkey/valkey:9.0.0-alpine@sha256:bef37d06d4856710973ee31dd1eac1482e4c8e6e7b847f999ad25433e646587b";
            pull = "missing";
            healthCmd = "valkey-cli PING";
            notify = "healthy";
            networks = opts.networks;
          };
        }
      ) config.valkey;
    };
  };
}
