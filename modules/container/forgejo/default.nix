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
    containers.forgejo.containerConfig = {
      image = "codeberg.org/forgejo/forgejo:15.0.3@sha256:55bb42bec9abef5223744804f164e37d37b20df7e8b8b4807ba213ad4f071d6d";
      pull = "missing";
      volumes = [
        "${volumes."forgejo".ref}:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      publishPorts = [
        "3000"
      ];
      networks = [
        networks."forgejo".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.forgejo = {
            rule = "Host(`trev.zip`)";
            middlewares = "secure@file";
          };
        };
      };
    };

    volumes = {
      forgejo = { };
    };

    networks = {
      forgejo = { };
    };
  };
}
