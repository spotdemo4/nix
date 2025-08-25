{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.prowlarr.containerConfig = {
      image = "lscr.io/linuxserver/prowlarr:2.0.5@sha256:4f2a6d597845b2f3e19284b1d982b3e0b4bd7c22472c2979c956aa198b83f472";
      pull = "missing";
      environments = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes.prowlarr.ref}:/config"
      ];
      publishPorts = [
        "9696"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.prowlarr = {
              rule = "HostRegexp(`prowlarr.trev.(zip|kiwi)`)";
              middlewares = "auth-github@docker";
            };
          };
        };
      };
    };

    volumes = {
      prowlarr = {};
    };
  };
}
