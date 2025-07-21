{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:latest@sha256:ae89f05ad7023258730ed62f5fcca63aab1e27ee5adcca1edb55d716f7cef356";
      pull = "missing";
      environments = {
        PUID = "1000";
        GUID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "/mnt/pool/movies:/movies"
        "${volumes.radarr.ref}:/config"
      ];
      publishPorts = [
        "7878"
      ];
      labels = toLabel [] {
        traefik = {
          enable = true;
          http.routers.radarr = {
            rule = "HostRegexp(`radarr.trev.(zip|kiwi)`)";
            middlewares = "auth-github@docker,header-basic@file";
          };
        };
      };
    };

    volumes = {
      radarr = {};
    };
  };
}
