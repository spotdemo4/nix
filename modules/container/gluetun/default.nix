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
    mkContainer
    mkImageOption
    networks
    secretType
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.gluetun;
  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;
in
{
  options.trev.containers.gluetun = {
    enable = mkEnableOption "Gluetun container instances";

    instances = mkOption {
      default = { };
      description = "Gluetun container instances.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "the ${name} Gluetun container";

              image = mkImageOption "docker.io/qmcgaw/gluetun:latest@sha256:12df8b20528d4cd5e9b6e827d40f2886cf78e53e7e9afc750050648c31183793";

              ports = mkOption {
                type = types.listOf types.str;
                default = [ "8080:8080" ];
                description = "Ports to publish from the container.";
              };

              environments = mkOption {
                type = types.attrsOf types.str;
                description = "Environment variables passed to Gluetun.";
                example = {
                  VPN_SERVICE_PROVIDER = "protonvpn";
                  VPN_TYPE = "wireguard";
                  SERVER_CITIES = "Chicago,Toronto";
                  PORT_FORWARD_ONLY = "on";
                  VPN_PORT_FORWARDING = "on";
                };
              };

              networks = networks;

              secret = mkOption {
                type = secretType;
                description = "Podman secret reference containing the WireGuard private key.";
              };

              volumeName = mkOption {
                type = types.str;
                default = "gluetun-${name}";
                description = "Name of the generated shared state volume.";
              };

              ref = mkOption {
                type = types.str;
                default = "gluetun-${name}";
                description = "Reference name for the Gluetun container.";
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
          containerConfig = mkContainer {
            image = instance.image;
            pull = "missing";
            devices = [
              "/dev/net/tun:/dev/net/tun"
            ];
            addCapabilities = [
              "NET_ADMIN"
            ];
            volumes = [
              "${volumes.${instance.volumeName}.ref}:/tmp/gluetun"
            ];
            healthCmd = "/gluetun-entrypoint healthcheck";
            notify = "healthy";
            secrets = [
              {
                inherit (instance.secret) ref;
                type = "env";
                target = "WIREGUARD_PRIVATE_KEY";
              }
            ];
            networks = instance.networks;
            environments = instance.environments;
            publishPorts = instance.ports;
          };
        }
      ) enabledInstances;

      volumes = mapAttrs' (_: instance: nameValuePair instance.volumeName { }) enabledInstances;
    };
  };
}
