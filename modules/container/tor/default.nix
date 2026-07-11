{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.tor;
  inherit (config.virtualisation.quadlet) networks volumes;
  torrc = pkgs.replaceVars ./torrc {
    inherit (cfg)
      bandwidthRate
      contactInfo
      metricsAllowedIP
      nickname
      ;
    metricsPort = toString cfg.metricsPort;
    orPort = toString cfg.orPort;
  };
in
{
  options.trev.containers.tor = {
    enable = mkEnableOption "the Tor relay container";

    image = containerOptions.mkImageOption "docker.io/dockurr/tor:0.4.9.11@sha256:dee1cc80ac1b761dec6168bf4e1460b1bc641b1ad3e6ac9c7c7295aff9f3f388";

    nickname = mkOption {
      type = types.str;
      default = "trevrelay";
      description = "Tor relay nickname.";
    };

    contactInfo = mkOption {
      type = types.str;
      default = "tor AT trev DOT kiwi";
      description = "Tor relay operator contact information.";
    };

    bandwidthRate = mkOption {
      type = types.str;
      default = "20 MBytes";
      description = "Advertised Tor relay bandwidth rate.";
    };

    orPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Tor relay OR port.";
    };

    metricsPort = mkOption {
      type = types.port;
      default = 9091;
      description = "Tor metrics port.";
    };

    metricsHostIP = mkOption {
      type = types.str;
      default = "10.10.10.105";
      description = "Host IP on which the Tor metrics port is published.";
    };

    metricsAllowedIP = mkOption {
      type = types.str;
      default = "10.10.10.109";
      description = "IP permitted to scrape Tor metrics.";
    };

    volumeName = mkOption {
      type = types.str;
      default = "tor";
      description = "Quadlet volume containing Tor relay state.";
    };

    networkName = mkOption {
      type = types.str;
      default = "tor";
      description = "Quadlet network used by the Tor relay.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.tor.containerConfig = {
        image = cfg.image;
        pull = "missing";
        volumes = [
          "${volumes.${cfg.volumeName}.ref}:/var/lib/tor"
          "${torrc}:/etc/tor/torrc"
        ];
        networks = [
          networks.${cfg.networkName}.ref
        ];
        publishPorts = [
          "${toString cfg.orPort}:${toString cfg.orPort}"
          "${cfg.metricsHostIP}:${toString cfg.metricsPort}:${toString cfg.metricsPort}"
        ];
      };

      volumes.${cfg.volumeName} = { };
      networks.${cfg.networkName} = { };
    };
  };
}
