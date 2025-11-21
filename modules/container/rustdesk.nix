{ config, ... }:
let
  inherit (config.virtualisation.quadlet) containers volumes;
in
{
  virtualisation.quadlet = {
    containers = {
      rustdesk-hbbs = {
        containerConfig = {
          image = "ghcr.io/rustdesk/rustdesk-server:1.1.12@sha256:9b1197d116f7bb4d3ad93a50bc1bc59ddb388de267df221a351f5ce10fac3dcf";
          pull = "missing";
          volumes = [
            "${volumes."rustdesk".ref}:/root"
          ];
          publishPorts = [
            "21115:21115" # NAT type test
            "21116:21116/tcp" # hole punching and connection service
            "21116:21116/udp" # ID registration and heartbeat service
          ];
          exec = "hbbs";
        };

        unitConfig = {
          After = containers."rustdesk-hbbr".ref;
          BindsTo = containers."rustdesk-hbbr".ref;
          ReloadPropagatedFrom = containers."rustdesk-hbbr".ref;
        };
      };

      rustdesk-hbbr.containerConfig = {
        image = "ghcr.io/rustdesk/rustdesk-server:1.1.12@sha256:9b1197d116f7bb4d3ad93a50bc1bc59ddb388de267df221a351f5ce10fac3dcf";
        pull = "missing";
        volumes = [
          "${volumes."rustdesk".ref}:/root"
        ];
        publishPorts = [
          "21117:21117" # relay service
        ];
        exec = "hbbr";
      };
    };

    volumes = {
      rustdesk = { };
    };
  };
}
