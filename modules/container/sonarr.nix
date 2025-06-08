{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:latest";
      pull = "newer";
      autoUpdate = "registry";
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
          http = {
            routers.sonarr = {
              rule = "Host(`sonarr.trev.zip`)";
              middlewares = "auth-github@docker,header-basic@file";
            };
          };
        };
      };
    };

    volumes = {
      sonarr = {};
    };
  };
}
