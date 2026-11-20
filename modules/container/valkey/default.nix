{
  self,
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
  inherit (import (self + /lib/container) { inherit lib; })
    args
    mkImageOption
    networks
    publishPorts
    ;
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

              image = mkImageOption "docker.io/valkey/valkey:9.2.0-alpine@sha256:c8e2d17498838af5d91e12eb7c11220b3434a7b7131a333e3af52ad5e0b80882";
              publishPorts = publishPorts;
              networks = networks;
              args = args;

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
