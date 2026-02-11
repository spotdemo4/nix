{ config, ... }:
let
  inherit (config.virtualisation.quadlet) containers volumes;
in
{
  virtualisation.quadlet = {
    containers = {
      rustdesk-hbbs = {
        containerConfig = {
          image = "ghcr.io/rustdesk/rustdesk-server:1.1.15@sha256:10818ec05b179039c6660f4d8e74b303f0db2858bbad2b18e24992ea22d54cd6";
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
        image = "ghcr.io/rustdesk/rustdesk-server:1.1.15@sha256:10818ec05b179039c6660f4d8e74b303f0db2858bbad2b18e24992ea22d54cd6";
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
