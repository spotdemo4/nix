{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:latest@sha256:4454c8cc644aeceb1f7c15237196cd415e5f8166922b893ee33e06c283533814";
      pull = "missing";
      environments = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "/mnt/pool/shows:/shows"
        "${volumes.sonarr.ref}:/config"
      ];
      publishPorts = [
        "8989"
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http.routers.sonarr = {
            rule = "HostRegexp(`sonarr.trev.(zip|kiwi)`)";
            middlewares = "auth-github@docker,header-basic@file";
          };
        };
      };
    };

    volumes = {
      sonarr = {};
    };
  };
}
