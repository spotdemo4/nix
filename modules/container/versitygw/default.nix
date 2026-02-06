{
  config,
  self,
  ...
}:
let
  toLabel = import (self + /modules/util/label);
  inherit (config) secrets;
in
{
  secrets."versitygw".file = self + /secrets/versitygw.age;

  virtualisation.quadlet = {
    containers.versitygw.containerConfig = {
      image = "docker.io/versity/versitygw:v1.1.0@sha256:f730e0dbc1ef3961aaab3e0560a804e64fe620c2cc6c58254fc303e197a17791";
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
  };
}
