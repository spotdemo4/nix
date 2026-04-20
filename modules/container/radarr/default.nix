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
      image = "lscr.io/linuxserver/radarr:6.1.1@sha256:b01097ad2d948c9f5eca39eb60bb529e2e55b0738c4bf7db09383bef0abab59d";
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
