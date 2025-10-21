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
      image = "ghcr.io/mizuchilabs/mantrae:v0.7.6@sha256:f711cfb4a5ede905d0cc3ea8af550df59ef5b7a57accc2a0bf2d936a8fea7f68";
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
