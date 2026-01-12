{ config, ... }:
let
  inherit (config.virtualisation.quadlet) containers volumes;
in
{
  virtualisation.quadlet = {
    containers = {
      rustdesk-hbbs = {
        containerConfig = {
          image = "ghcr.io/rustdesk/rustdesk-server:1.1.15@sha256:2554c35d71a71a4c4c342afe0c5b3bd42af4d581a821638ca1631eddbb2ae076";
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
        image = "ghcr.io/rustdesk/rustdesk-server:1.1.15@sha256:2554c35d71a71a4c4c342afe0c5b3bd42af4d581a821638ca1631eddbb2ae076";
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
