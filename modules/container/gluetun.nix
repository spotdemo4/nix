{
  lib,
  config,
  self,
  ...
}:
with lib;
let
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.gluetun = mkOption {
    default = { };
    description = "Gluetun container configurations";

    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            ports = mkOption {
              type = types.listOf types.str;
              default = [ "8080:8080" ];
              description = ''
                The ports to publish from the container
              '';
            };

            environments = mkOption {
              type = types.attrs;
              example = {
                VPN_SERVICE_PROVIDER = "protonvpn";
                VPN_TYPE = "wireguard";
                SERVER_CITIES = "Chicago,Toronto";
                PORT_FORWARD_ONLY = "on";
                VPN_PORT_FORWARDING = "on";
              };
            };

            networks = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Additional networks to connect the container to
              '';
            };

            secret = mkOption {
              type = types.submodule (import (self + /modules/util/secrets/secret.nix));
              description = ''
                Wireguard private key secret
              '';
            };

            ref = mkOption {
              type = types.str;
              description = "Reference name for the mysql container";
              default = "gluetun-${name}";
            };
          };
        }
      )
    );
  };

  config = mkIf (config.gluetun != { }) {
    virtualisation.quadlet = {
      containers = mapAttrs' (
        name: opts:
        nameValuePair "gluetun-${name}" {
          containerConfig = {
            image = "docker.io/qmcgaw/gluetun:latest@sha256:870a9d5880182a3902004c32d3827d0b098e30a4f74d3cc7742512e23d3888df";
            pull = "missing";
            devices = [
              "/dev/net/tun:/dev/net/tun"
            ];
            addCapabilities = [
              "NET_ADMIN"
            ];
            volumes = [
              "${volumes."gluetun-${name}".ref}:/tmp/gluetun"
            ];
            healthCmd = "/gluetun-entrypoint healthcheck";
            notify = "healthy";
            secrets = [
              "${opts.secret.env},target=WIREGUARD_PRIVATE_KEY"
            ];
            networks = opts.networks;
            environments = opts.environments;
            publishPorts = opts.ports;
          };
        }
      ) config.gluetun;

      volumes = mapAttrs' (name: _: nameValuePair "gluetun-${name}" { }) config.gluetun;
    };
  };
}
