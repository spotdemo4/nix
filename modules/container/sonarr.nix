{config, ...}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = (import ./utils/toLabel.nix).toLabel;
in {
  virtualisation.quadlet = {
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:latest@sha256:1a90192952c30f9420994b2e2171083ea8cae100357de5e9eb25890efa90a6ce";
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
