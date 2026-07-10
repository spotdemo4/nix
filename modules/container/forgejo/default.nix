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
      image = "codeberg.org/forgejo/forgejo:15.0.4@sha256:9e14382433760127c87cb78c4dbc44b45abbb0c09c8479812c8e99b3dc893429";
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
