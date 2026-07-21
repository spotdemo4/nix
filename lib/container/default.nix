{ lib }:
let
  inherit (lib) mkOption types;
  toLabel = import ../label;
  toStructuredSecret =
    {
      ref,
      type ? null,
      target ? null,
      uid ? null,
      gid ? null,
      mode ? null,
    }:
    if
      type != null
      && !builtins.elem type [
        "mount"
        "env"
      ]
    then
      throw "container secret type must be either mount or env"
    else if type == "env" && (uid != null || gid != null || mode != null) then
      throw "container secret uid, gid, and mode options require type = mount"
    else
      let
        attrs = {
          inherit
            type
            target
            uid
            gid
            mode
            ;
        };
        options =
          builtins.concatMap (name: lib.optional (attrs.${name} != null) "${name}=${toString attrs.${name}}")
            [
              "type"
              "target"
              "uid"
              "gid"
              "mode"
            ];
      in
      lib.concatStringsSep "," ([ ref ] ++ options);
  toSecret = secret: if builtins.isString secret then secret else toStructuredSecret secret;
in
{
  mkContainer =
    config:
    config
    // lib.optionalAttrs ((config ? labels) && builtins.isAttrs config.labels) {
      labels = toLabel { attrs = config.labels; };
    }
    // lib.optionalAttrs (config ? secrets) {
      secrets = map toSecret config.secrets;
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
