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
      image = "lscr.io/linuxserver/sonarr:4.0.17@sha256:b5670a3adb0f8a8b0f277feeaa69a5fbe3869ba4bb9fa7c0f0764c3b3f0e698f";
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
