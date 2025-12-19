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
      image = "ghcr.io/zimpatrick/cobalt:staging@sha256:beaeb6df54276480edea826287c60b5c8b7224a35663111b2137d18f17eae500";
      pull = "missing";
      environments = {
        API_URL = "https://cobalt.trev.zip/";
      };
      networks = [
        "container:${gluetun."cobalt".ref}"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.cobalt = {
            rule = "Host(`cobalt.trev.zip`)";
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
