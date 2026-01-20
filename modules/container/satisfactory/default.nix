{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.satisfactory.containerConfig = {
      image = "ghcr.io/wolveix/satisfactory-server:v1.9.10@sha256:e0f2f8c9759875c97add050d3a344167b71cb41bef68e85771f1ea8cc8c00301";
      pull = "missing";
      environments = {
        MAXPLAYERS = "4";
        PGID = "1000";
        PUID = "1000";
        STEAMBETA = "false";
      };
      volumes = [
        "${volumes."satisfactory".ref}:/config"
      ];
      publishPorts = [
        "7777:7777/tcp" # satisfactory-server
        "7777:7777/udp" # satisfactory-query
        "8888:8888/tcp" # satisfactory-game
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          tcp = {
            services = {
              satisfactory-server.loadbalancer.server.port = 7777;
              satisfactory-game.loadbalancer.server.port = 8888;
            };
            routers = {
              satisfactory-server = {
                rule = "HostSNI(`*`)";
                entryPoints = "satisfactory-server";
                service = "satisfactory-server";
              };
              satisfactory-game = {
                rule = "HostSNI(`*`)";
                entryPoints = "satisfactory-game";
                service = "satisfactory-game";
              };
            };
          };
          udp = {
            services.satisfactory-query.loadbalancer.server.port = 7777;
            routers.satisfactory-query = {
              entryPoints = "satisfactory-query";
              service = "satisfactory-query";
            };
          };
        };
      };
    };

    volumes = {
      satisfactory = { };
    };
  };
}
