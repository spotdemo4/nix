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
            image = "docker.io/valkey/valkey:9.0.1-alpine@sha256:1be494495248d53e3558b198a1c704e6b559d5e99fe4c926e14a8ad24d76c6fa";
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
