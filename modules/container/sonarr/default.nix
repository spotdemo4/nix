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
    containers.sonarr.containerConfig = {
      image = "lscr.io/linuxserver/sonarr:4.0.19@sha256:c4f53fe482d480bb4c43623eb12f53ad2f69634e5dbd1598c05a4eab9eabda92";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.sonarr.ref}:/config"
        "/mnt/pool:/pool"
      ];
      publishPorts = [
        "8989"
      ];
      networks = [
        networks."sonarr".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.sonarr = {
            rule = "HostRegexp(`sonarr.trev.(zip|kiwi)`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };

    volumes = {
      sonarr = { };
    };

    networks = {
      sonarr = { };
    };
  };
}
