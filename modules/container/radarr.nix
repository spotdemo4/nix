{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:latest";
      pull = "newer";
      autoUpdate = "registry";
      environments = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "/mnt/pool/movies:/movies"
        "${volumes.radarr_data.ref}:/config"
      ];
      publishPorts = [
        "7878"
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http = {
            routers.radarr = {
              rule = "Host(`radarr.trev.zip`)";
              entryPoints = "https";
              tls.certresolver = "letsencrypt";
              middlewares = "oauth@docker";
            };
          };
        };
      };
    };

    volumes = {
      radarr_data = {};
    };
  };
}
