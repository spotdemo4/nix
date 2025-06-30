{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:latest@sha256:1156329d544b38bd1483add75c9b72c559f20e1ca043fd2d6376c2589d38951f";
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
