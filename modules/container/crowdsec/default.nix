{
  config,
  ...
}:
let
  inherit (config.virtualisation.quadlet) volumes;
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
        "${./traefik.yaml}:/etc/crowdsec/acquis.d/traefik.yaml:ro"
        "${./attic.yaml}:/etc/crowdsec/parsers/s02-enrich/attic.yaml:ro"
      ];
      publishPorts = [
        "6061:8080" # api
        "6060:6060" # prometheus
      ];
    };

    volumes = {
      crowdsec-db = { };
      crowdsec-config = { };
    };
  };
}
