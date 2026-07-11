{
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
  containerOptions = import ../../../lib/container-options.nix { inherit lib; };
  cfg = config.trev.containers.crowdsec;
  inherit (config.virtualisation.quadlet) volumes;
in
{
  options.trev.containers.crowdsec = {
    enable = mkEnableOption "CrowdSec container";

    image = containerOptions.mkImageOption "docker.io/crowdsecurity/crowdsec:v1.7.8@sha256:2f527c9bb8b367120eb08b82890aa912ce96bfa1ada93dda0721700e4b4e0dde";

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
  };
}
