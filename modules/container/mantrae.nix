{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);
in
{
  secrets = {
    "mantrae-password".file = self + /secrets/mantrae-password.age;
    "mantrae-secret".file = self + /secrets/mantrae-secret.age;
  };

  virtualisation.quadlet = {
    containers.mantrae.containerConfig = {
      image = "ghcr.io/mizuchilabs/mantrae:0.8.5@sha256:d80adfe4d010cdf20b886241d499e3e3748c0b56346561cd7803ad8bf8240029";
      pull = "missing";
      secrets = [
        "${secrets."mantrae-password".env},target=ADMIN_PASSWORD"
        "${secrets."mantrae-secret".env},target=SECRET"
      ];
      volumes = [
        "${volumes."mantrae".ref}:/data"
      ];
      networks = [
        networks."traefik".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http = {
            routers.mantrae = {
              rule = "HostRegexp(`mantrae.trev.(zip|kiwi)`)";
              middlewares = "secure-trev@file";
            };
            services.mantrae.loadbalancer.server = {
              scheme = "http";
              port = 3000;
            };
          };
        };
      };
    };

    volumes = {
      mantrae = { };
    };
  };
}
