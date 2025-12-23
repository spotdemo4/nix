{
  config,
  self,
  pkgs,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);

  accounts = "/accounts.conf";
  cfg = pkgs.replaceVars ./copyparty.conf {
    accounts = accounts;
  };
in
{
  secrets = {
    "copyparty".file = self + /secrets/copyparty.age;
  };

  virtualisation.quadlet = {
    containers.copyparty.containerConfig = {
      image = "ghcr.io/9001/copyparty-ac:1.19.23@sha256:d32d2bff2e0401bc7e402bc9d8ef011de39eb7ee98f20645e1081ec1be629318";
      pull = "missing";
      user = "1000:1000";
      secrets = [
        "${secrets."copyparty".mount},target=${accounts}"
      ];
      volumes = [
        "/mnt/files:/w"
        "${cfg}:/cfg/copyparty.conf"
        "${volumes."copyparty".ref}:/db"
      ];
      publishPorts = [
        "3923"
      ];
      labels = toLabel {
        attrs = {
          traefik = {
            enable = true;
            http.routers.copyparty = {
              rule = "Host(`files.trev.zip`)";
              middlewares = "secure@file";
            };
          };
        };
      };
    };

    volumes = {
      copyparty = { };
    };
  };
}
