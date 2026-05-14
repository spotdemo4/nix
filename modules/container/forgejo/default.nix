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
      image = "codeberg.org/forgejo/forgejo:15.0.2@sha256:db04c7114b656f896e206ba3873fe8d3a7adf2daa44907037f0274f4ba653fb9";
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
