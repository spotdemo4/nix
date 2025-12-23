{
  config,
  self,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
  toLabel = import (self + /modules/util/label);
in
{
  virtualisation.quadlet = {
    containers.crowdsec.containerConfig = {
      image = "docker.io/crowdsecurity/crowdsec:v1.7.4@sha256:4312a5109057f2a6b1237431abe638cd1026ecb3a9c2707c6ccc1ed09e4cb994";
      pull = "missing";
      environments = {
        COLLECTIONS = "crowdsecurity/linux crowdsecurity/traefik";
        TZ = "America/Detroit";
      };
      volumes = [
        "${volumes."crowdsec-db".ref}:/var/lib/crowdsec/data/"
        "${volumes."crowdsec-config".ref}:/etc/crowdsec/"
        "${./ssh.yaml}:/etc/crowdsec/acquis.d/ssh.yaml:ro"
        "${./traefik.yaml}:/etc/crowdsec/acquis.d/traefik.yaml:ro"
      ];
      publishPorts = [
        "8080"
      ];
      labels = toLabel {
        attrs.traefik = {
          enable = true;
          http.routers.sonarr = {
            rule = "Host(`crowdsec.trev.xyz`)";
            middlewares = "secure-admin@file";
          };
        };
      };
    };

    volumes = {
      crowdsec-db = { };
      crowdsec-config = { };
    };
  };
}
