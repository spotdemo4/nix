{
  config,
  self,
  ...
}: let
  inherit (config.virtualisation.quadlet) networks volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);
in {
  secrets = {
    "mantrae-password".file = self + /secrets/mantrae-password.age;
    "mantrae-secret".file = self + /secrets/mantrae-secret.age;
  };

  virtualisation.quadlet = {
    containers.mantrae.containerConfig = {
      image = "ghcr.io/mizuchilabs/mantrae:0.7.8@sha256:97edc56e347da1a0cc188746bd04c613e15a853ff5ae7db39516946061d46cd9";
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
              middlewares = "auth-github@docker";
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
      mantrae = {};
    };
  };
}
