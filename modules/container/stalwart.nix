{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) volumes;
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
        "25:25" # SMTP
        "465:465" # SMTPS
        "993:993" # IMAPS
        "8080:8080" # HTTP
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
  };
}
