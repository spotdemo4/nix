{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  toLabel = import (self + /modules/util/label);
in {
  virtualisation.quadlet = {
    containers.stalwart.containerConfig = {
      image = "docker.io/stalwartlabs/stalwart:v0.13.3-alpine@sha256:7d29abe559d363607d2cf2e10bc31bd83074d566dfc4a9981fda612484b4ee32";
      pull = "missing";
      volumes = [
        "${volumes.stalwart.ref}:/opt/stalwart"
      ];
      publishPorts = [
        "25:25" # smtp
        "465:465" # smtps
        "993:993" # imaps
        "8080:8080" # http
      ];
      networks = [
        networks.stalwart.ref
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            tcp.routers.stalwart = {
              rule = "HostSNI(`*`)";
              entryPoints = "smtp,smtps,imaps";
            };
            http = {
              routers.stalwart = {
                rule = "HostRegexp(`mail.trev.(zip|kiwi)`)";
                middlewares = "auth-github@docker";
              };
              services.stalwart.loadbalancer.server = {
                scheme = "http";
                port = 8080;
              };
            };
          };
        };
      };
    };

    volumes = {
      stalwart = {};
    };

    networks = {
      stalwart = {};
    };
  };
}
