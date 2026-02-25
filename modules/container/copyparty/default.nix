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
      image = "ghcr.io/9001/copyparty-ac:1.20.9@sha256:885f1a4e6d41b1033d474fdab2835d353fe9b266257608e3d8ab33d0bd3e4225";
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
