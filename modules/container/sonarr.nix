{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:latest@sha256:b0ac15772c04f329964ed79cb446ab23fd1ee28f33b58b10f0264feac17d33cd";
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
