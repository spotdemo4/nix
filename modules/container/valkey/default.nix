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
            image = "docker.io/valkey/valkey:9.0.0-alpine@sha256:4a3c001f7c2f21186075ea0ccca19fea88b4ab108465d7ef4406958e77aac45b";
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
