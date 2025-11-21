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
    containers.prowlarr.containerConfig = {
      image = "lscr.io/linuxserver/prowlarr:2.3.0@sha256:3dd3a316f60ea4e6714863286549a6ccaf0b8cf4efe5578ce3fe0e85475cb1cf";
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
      networks = [
        networks."sonarr".ref
        networks."radarr".ref
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
      prowlarr = { };
    };
  };
}
