{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) networks;
  inherit (config) secrets;
  toLabel = import (self + /modules/util/label);
in
{
  secrets."versitygw".file = self + /secrets/versitygw.age;

  virtualisation.quadlet = {
    containers.versitygw.containerConfig = {
      image = "docker.io/versity/versitygw:v1.3.0@sha256:035ca86a38033c92c31a2a3dd54aa37581737c03e872154130306dac50580ad2";
      pull = "missing";
      environments = {
        VGW_BACKEND = "posix";
        VGW_BACKEND_ARG = "/data";
        ROOT_ACCESS_KEY = "trev";
      };
      secrets = [
        "${secrets."versitygw".env},target=ROOT_SECRET_KEY"
      ];
      volumes = [
        "/mnt/versitygw:/data"
      ];
      publishPorts = [
        "7070"
      ];
      networks = [
        networks."versitygw".ref
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.versitygw = {
            rule = "Host(`s3.trev.zip`)";
            middlewares = "secure@file";
          };
        };
      };
    };

    networks = {
      versitygw = { };
    };
  };
}
