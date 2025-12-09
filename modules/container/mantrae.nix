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
      image = "ghcr.io/mizuchilabs/mantrae:0.8.1@sha256:45a681442a03060c77c9a073d6a19ebe16b2bce73ba3df0ce8ca3b6e81b3d7a4";
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
      mantrae = { };
    };
  };
}
