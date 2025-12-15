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
      image = "ghcr.io/9001/copyparty-ac:1.19.22@sha256:3e114ac7d3472eefed370cd96dcad2ca36046246caea72397d8015572c54945b";
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
              rule = "Host(`trev.zip`)";
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
