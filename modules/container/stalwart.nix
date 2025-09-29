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
        "/mnt/certs:/data/certs:ro"
      ];
      publishPorts = [
        "25:25" # smtp
        "443:443" # https
        "465:465" # smtps
        "993:993" # imaps
        "8080:8080" # http
      ];
      networks = [
        networks.stalwart.ref
      ];
      ip = "10.98.98.98";
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          tcp = {
            routers = {
              smtp = {
                rule = "HostSNI(`*`)";
                service = "smtp";
                entryPoints = "smtp";
              };
              jmap = {
                rule = "HostSNI(`*`)";
                service = "jmap";
                entryPoints = "https";
                tls.passthrough = true;
              };
              smtps = {
                rule = "HostSNI(`*`)";
                service = "smtps";
                entryPoints = "smtps";
                tls.passthrough = true;
              };
              imaps = {
                rule = "HostSNI(`*`)";
                service = "imaps";
                entryPoints = "imaps";
                tls.passthrough = true;
              };
            };
            services = {
              smtp.loadbalancer = {
                server.port = 25;
                serversTransport = "proxy@file";
              };
              jmap.loadbalancer = {
                server.port = 443;
                serversTransport = "proxy@file";
              };
              smtps.loadbalancer = {
                server.port = 465;
                serversTransport = "proxy@file";
              };
              imaps.loadbalancer = {
                server.port = 993;
                serversTransport = "proxy@file";
              };
            };
          };
          http = {
            routers.stalwart = {
              rule = "Host(`mail.trev.kiwi`) || Host(`mail.trev.zip`) || HostRegexp(`autodiscover.trev.(zip|kiwi)`) || HostRegexp(`autoconfig.trev.(zip|kiwi)`) || HostRegexp(`mta-sts.trev.(zip|kiwi)`)";
              entrypoints = "https";
              service = "stalwart";
            };
            services.stalwart.loadbalancer.server = {
              port = 8080;
            };
          };
        };
      };
    };

    volumes = {
      stalwart = {};
    };

    networks = {
      stalwart = {
        networkConfig.subnets = [
          "10.98.98.0/24"
        ];
      };
    };
  };
}
