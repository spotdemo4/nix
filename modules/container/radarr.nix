{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:latest@sha256:07a474b61394553e047ad43a1a78c1047fc99be0144c509dd91e3877f402ebcb";
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
