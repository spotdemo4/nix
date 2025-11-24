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
      image = "ghcr.io/mizuchilabs/mantrae:0.7.9@sha256:68084ddc748a0c9627b71d17d2e8430e9b91b8771c913855ba818108754ec949";
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
