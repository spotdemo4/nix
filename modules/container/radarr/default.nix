{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.radarr.containerConfig = {
      image = "lscr.io/linuxserver/radarr:6.1.1@sha256:079e48870584baf2a3e7e43e7ba6d3c834555931851a59c82c51cc792d285caf";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.radarr.ref}:/config"
        "/mnt/pool:/pool"
      ];
      publishPorts = [
        "7878"
      ];
      networks = [
        networks."radarr".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.radarr = {
            rule = "HostRegexp(`radarr.trev.(zip|kiwi)`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };

    volumes = {
      radarr = { };
    };

    networks = {
      radarr = { };
    };
  };
}
