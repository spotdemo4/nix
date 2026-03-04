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
      image = "docker.io/versity/versitygw:v1.3.1@sha256:a86791b684a1dd3c5a255ca755bb51783a72696cf1b5a843f800b08bfd6f921c";
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
