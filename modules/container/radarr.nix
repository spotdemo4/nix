{config, ...}: {
  virtualisation.quadlet = let
    toLabel = (import ./utils/toLabel.nix).toLabel;
    inherit (config.virtualisation.quadlet) volumes;
  in {
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
              middlewares = "authelia@docker";
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
