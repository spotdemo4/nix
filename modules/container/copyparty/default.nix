{
  config,
  self,
  pkgs,
  ...
}:
let
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

  virtualisation.quadlet.containers.copyparty.containerConfig = {
    image = "ghcr.io/9001/copyparty-ac:1.19.20@sha256:81bae1a42e0ad879231f84eeb88f6a8b7dc943e84c1fb838dd44ccfac0fffc5a";
    pull = "missing";
    secrets = [
      "${secrets."copyparty".mount},target=${accounts}"
    ];
    volumes = [
      "/mnt/files:/w"
      "${cfg}:/cfg/copyparty.conf"
    ];
    publishPorts = [
      "3923"
    ];
    labels = toLabel {
      attrs = {
        traefik = {
          enable = true;
          http.routers.copyparty = {
            rule = "HostRegexp(`trev.zip`)";
          };
        };
      };
    };
  };
}
