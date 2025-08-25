{
  lib,
  config,
  self,
  ...
}:
with lib; let
  cfg = config.gluetun;
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  options.gluetun = mkOption {
    default = {};
    description = "Gluetun container configurations";
    type = types.attrsOf (types.submodule {
      options = {
        ports = mkOption {
          type = types.listOf types.str;
          default = ["8080:8080"];
          description = ''
            The ports to publish from the container
          '';
        };

        labels = mkOption {
          type = types.attrs;
          example = {
            traefik = {
              enable = true;
              http.routers.gluetun = {
                rule = "HostRegexp(`example.trev.(zip|kiwi)`)";
                middlewares = "auth-github@docker";
              };
            };
          };
        };

        secret = mkOption {
          type = types.submodule (import (self + /modules/util/secrets/secret.nix));
          description = ''
            Wireguard private key secret
          '';
        };
      };
    });
  };

  config = mkIf (cfg != {}) {
    virtualisation.quadlet = {
      containers = mapAttrs' (name: opts:
        nameValuePair "gluetun-${name}" {
          containerConfig = {
            image = "docker.io/qmcgaw/gluetun:latest@sha256:29be3ff9a71ecc5ddb6716b5a4859b1af5712a6debe90ca69b100ef784845bbc";
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
            environments = {
              VPN_SERVICE_PROVIDER = "protonvpn";
              VPN_TYPE = "wireguard";
              SERVER_CITIES = "Chicago,Toronto";
              PORT_FORWARD_ONLY = "on";
              VPN_PORT_FORWARDING = "on";
            };
            publishPorts = opts.ports;
            labels = toLabel [] opts.labels;
            secrets = [
              "${opts.secret.env},target=WIREGUARD_PRIVATE_KEY"
            ];
          };
        })
      cfg;

      volumes = mapAttrs' (name: _: nameValuePair "gluetun-${name}" {}) cfg;
    };
  };
}
