{
  lib,
  config,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  options.gluetun = {
    enable = lib.mkEnableOption "enable gluetun";

    name = lib.mkOption {
      type = lib.types.str;
      default = "example";
      description = ''
        The name for the gluetun instance
      '';
    };

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["8080:8080"];
      description = ''
        The ports to publish from the container
      '';
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = [];
      description = ''
        Secret name for the private key
      '';
    };

    labels = lib.mkOption {
      type = lib.types.attrs;
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
  };

  config = lib.mkIf config.gluetun.enable {
    virtualisation.quadlet = {
      containers."gluetun-${config.gluetun.name}".containerConfig = {
        image = "docker.io/qmcgaw/gluetun:latest@sha256:29be3ff9a71ecc5ddb6716b5a4859b1af5712a6debe90ca69b100ef784845bbc";
        pull = "missing";
        devices = [
          "/dev/net/tun:/dev/net/tun"
        ];
        addCapabilities = [
          "NET_ADMIN"
        ];
        volumes = [
          "${volumes."gluetun-${config.gluetun.name}".ref}:/tmp/gluetun"
        ];
        environments = {
          VPN_SERVICE_PROVIDER = "protonvpn";
          VPN_TYPE = "wireguard";
          SERVER_CITIES = "Chicago,Toronto";
          PORT_FORWARD_ONLY = "on";
          VPN_PORT_FORWARDING = "on";
        };
        secrets = [
          "${config.gluetun.privateKeySecret},type=env,target=WIREGUARD_PRIVATE_KEY"
        ];
        publishPorts = config.gluetun.ports;
        labels = toLabel [] config.gluetun.labels;
      };

      volumes."gluetun-${config.gluetun.name}" = {};
    };
  };
}
