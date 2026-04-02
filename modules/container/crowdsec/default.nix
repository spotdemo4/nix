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
      image = "docker.io/crowdsecurity/crowdsec:v1.7.7@sha256:6ca53ad26196ca59ddd4fa692a586b73d8fcde085046163b9ca2f04887dca563";
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
        "${./versitygw.yaml}:/etc/crowdsec/parsers/s02-enrich/versitygw.yaml:ro"
        "${./garage.yaml}:/etc/crowdsec/parsers/s02-enrich/garage.yaml:ro"
        "${./niks3.yaml}:/etc/crowdsec/parsers/s02-enrich/niks3.yaml:ro"
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
