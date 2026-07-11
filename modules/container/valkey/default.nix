{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.valkey;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
in
{
  options.trev.containers.valkey = {
    enable = mkEnableOption "Valkey container instances";

    instances = mkOption {
      default = { };
      description = "Valkey container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} Valkey container";

              image = containerOptions.mkImageOption "docker.io/valkey/valkey:9.1.0-alpine@sha256:a35428eba9043cc0b79dbe54100f0c92784f2de00ad09b01182bfb1c5c83d1bd";
              publishPorts = containerOptions.publishPorts;
              networks = containerOptions.networks;
              args = containerOptions.args;

              ref = mkOption {
                type = types.str;
                default = "valkey-${name}";
                description = "Reference name for the Valkey container.";
              };
            };
          }
        )
      );
    };
  };

  config = mkIf (cfg.enable && enabledInstances != { }) {
    virtualisation.quadlet = {
      containers = mapAttrs' (
        _: instance:
        nameValuePair instance.ref {
          containerConfig = {
            image = instance.image;
            pull = "missing";
            healthCmd = "valkey-cli PING";
            notify = "healthy";
            publishPorts = instance.publishPorts;
            networks = instance.networks;
            environments = {
              VALKEY_EXTRA_FLAGS = builtins.concatStringsSep " " instance.args;
            };
          };
        }
      ) enabledInstances;
    };
  };
}
