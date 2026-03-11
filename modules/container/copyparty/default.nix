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
      image = "ghcr.io/9001/copyparty-ac:1.20.12@sha256:244433d3ee46c73c85882ecb47d9dfe1c29ce8274f9fd038c5a1bea258c1a3aa";
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
