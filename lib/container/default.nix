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

  secretReferenceType = types.submodule (import ../secrets/secret.nix);
}
