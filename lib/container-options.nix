{ lib }:
let
  inherit (lib) mkOption types;
  toLabel = import ./label;
in
{
  mkContainer =
    config:
    config
    // lib.optionalAttrs ((config ? labels) && builtins.isAttrs config.labels) {
      labels = toLabel { attrs = config.labels; };
    };

  mkImageOption =
    default:
    mkOption {
      inherit default;
      type = types.str;
      description = "Container image reference.";
    };

  networks = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Quadlet network references to attach to the container.";
  };

  publishPorts = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Ports to publish from the container.";
  };

  args = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Additional arguments passed to the container application.";
  };

  secretReferenceType = types.submodule (
    { config, name, ... }:
    {
      options = {
        ref = mkOption {
          type = types.str;
          default = name;
          description = "Podman secret name.";
        };

        env = mkOption {
          type = types.str;
          default = "${config.ref},type=env";
          description = "Podman environment secret reference.";
        };

        mount = mkOption {
          type = types.str;
          default = "${config.ref},type=mount";
          description = "Podman mount secret reference.";
        };

        file = mkOption {
          type = types.nullOr (types.either types.path types.str);
          default = null;
          description = "Optional source file carried by an existing secret configuration.";
        };

        path = mkOption {
          type = types.str;
          default = "/run/agenix/${config.ref}";
          description = "Optional decrypted path carried by an existing secret configuration.";
        };
      };
    }
  );
}
