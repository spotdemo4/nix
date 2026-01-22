{
  config,
  self,
  ...
}:
let
  inherit (config) gluetun secrets;
  toLabel = import (self + /modules/util/label);
in
{
  imports = [
    (self + /modules/container/gluetun.nix)
    ./web.nix
  ];

  secrets = {
    "protonvpn-cobalt".file = self + /secrets/protonvpn-cobalt.age;
  };

  gluetun."cobalt" = {
    secret = secrets."protonvpn-cobalt";
    ports = [ "9000" ];
    environments = {
      VPN_SERVICE_PROVIDER = "protonvpn";
      VPN_TYPE = "wireguard";
      SERVER_CITIES = "Chicago,Toronto";
      STREAM_ONLY = "on";
    };
  };

  virtualisation.quadlet.containers.cobalt = {
    containerConfig = {
      image = "git.canine.tools/canine.tools/cobalt:api@sha256:8ed45d47170180eb59feb1b76abf3ca6c61f98f279156e2bbc67d4bd2a99212f";
      pull = "missing";
      environments = {
        API_URL = "https://cobalt-api.trev.zip/";
      };
      networks = [
        "container:${gluetun."cobalt".ref}"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.cobalt = {
            rule = "Host(`cobalt-api.trev.zip`)";
          };
        };
      };
    };

    unitConfig = {
      After = gluetun."cobalt".ref;
      BindsTo = gluetun."cobalt".ref;
      ReloadPropagatedFrom = gluetun."cobalt".ref;
    };
  };
}
