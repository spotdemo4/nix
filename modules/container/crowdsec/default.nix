{
  self,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (import (self + /lib/container) { inherit lib; })
    mkImageOption
    ;
  inherit (config.virtualisation.quadlet)
    volumes
    ;
  cfg = config.trev.containers.crowdsec;
in
{
  options.trev.containers.crowdsec = {
    enable = mkEnableOption "CrowdSec container";

    image = mkImageOption "docker.io/crowdsecurity/crowdsec:v1.7.8@sha256:2f527c9bb8b367120eb08b82890aa912ce96bfa1ada93dda0721700e4b4e0dde";

    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by CrowdSec.";
    };

    profilesFile = mkOption {
      type = types.path;
      default = ./profiles.yaml;
      description = "CrowdSec profiles configuration file.";
    };

    traefikAcquisitionFile = mkOption {
      type = types.path;
      default = ./traefik.yaml;
      description = "CrowdSec Traefik acquisition configuration file.";
    };

    atticParserFile = mkOption {
      type = types.path;
      default = ./attic.yaml;
      description = "CrowdSec Attic parser configuration file.";
    };

    garageParserFile = mkOption {
      type = types.path;
      default = ./garage.yaml;
      description = "CrowdSec Garage parser configuration file.";
    };

    niks3ParserFile = mkOption {
      type = types.path;
      default = ./niks3.yaml;
      description = "CrowdSec Niks3 parser configuration file.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.quadlet = {
      containers.crowdsec.containerConfig = {
        image = cfg.image;
        pull = "missing";
        environments = {
          COLLECTIONS = "crowdsecurity/linux crowdsecurity/traefik";
          TZ = cfg.timeZone;
        };
        volumes = [
          "${volumes."crowdsec-db".ref}:/var/lib/crowdsec/data/"
          "${volumes."crowdsec-config".ref}:/etc/crowdsec/"
          "${cfg.profilesFile}:/etc/crowdsec/profiles.yaml:ro"
          "${cfg.traefikAcquisitionFile}:/etc/crowdsec/acquis.d/traefik.yaml:ro"
          "${cfg.atticParserFile}:/etc/crowdsec/parsers/s02-enrich/attic.yaml:ro"
          "${cfg.garageParserFile}:/etc/crowdsec/parsers/s02-enrich/garage.yaml:ro"
          "${cfg.niks3ParserFile}:/etc/crowdsec/parsers/s02-enrich/niks3.yaml:ro"
          "${./http-distributed-subnet-v4.yaml}:/etc/crowdsec/scenarios/trev-http-distributed-subnet-v4.yaml:ro"
          "${./http-distributed-subnet-v6.yaml}:/etc/crowdsec/scenarios/trev-http-distributed-subnet-v6.yaml:ro"
        ];
        publishPorts = [
          "6061:8080" # api
          "6060:6060" # prometheus
        ];
        healthCmd = "current=\"$(wget -qO- http://127.0.0.1:6060/metrics | awk '/^cs_victorialogssource_hits_total/ { print $2; exit }')\" || exit 1; test -n \"$current\" || exit 1; previous=\"$(cat /tmp/crowdsec-victorialogs-lines 2>/dev/null || true)\"; printf '%s\\n' \"$current\" > /tmp/crowdsec-victorialogs-lines; test -z \"$previous\" || test \"$current\" != \"$previous\"";
        healthInterval = "1m";
        healthTimeout = "10s";
        healthStartPeriod = "2m";
        healthRetries = 5;
        healthOnFailure = "kill";
      };

      volumes = {
        crowdsec-db = { };
        crowdsec-config = { };
      };
    };
  };
}
