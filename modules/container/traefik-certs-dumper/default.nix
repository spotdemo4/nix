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
    containers
    volumes
    ;
  cfg = config.trev.containers.traefik-certs-dumper;
  traefik = lib.attrByPath [ "trev" "containers" "traefik" ] {
    enable = false;
    acmeVolumeName = "acme";
  } config;
  traefikContainer = lib.attrByPath [ cfg.traefikContainerName ] {
    ref = cfg.traefikContainerName;
  } containers;
in
{
  options.trev.containers.traefik-certs-dumper = {
    enable = mkEnableOption "the Traefik certificate dumper container";

    image = mkImageOption "ghcr.io/kereis/traefik-certs-dumper:1.8.22@sha256:9d71a7cc50d4b00ac30a27ffc94cca375953cd11ebc722772943823528497996";

    outputDir = mkOption {
      type = types.str;
      default = "/mnt/certs";
      description = "Host directory receiving dumped certificates.";
    };

    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used to run the certificate dumper.";
    };

    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used to run the certificate dumper.";
    };

    acmeVolumeName = mkOption {
      type = types.str;
      default = "acme";
      description = "Quadlet volume containing Traefik ACME state.";
    };

    traefikContainerName = mkOption {
      type = types.str;
      default = "traefik";
      description = "Quadlet container on which the certificate dumper depends.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = traefik.enable;
        message = "trev.containers.traefik-certs-dumper requires trev.containers.traefik.enable = true";
      }
      {
        assertion = cfg.traefikContainerName == "traefik";
        message = "trev.containers.traefik-certs-dumper.traefikContainerName must name the Traefik module's 'traefik' container";
      }
      {
        assertion = cfg.acmeVolumeName == traefik.acmeVolumeName;
        message = "trev.containers.traefik-certs-dumper.acmeVolumeName must match trev.containers.traefik.acmeVolumeName";
      }
    ];

    virtualisation.quadlet = {
      containers.traefik-certs-dumper = {
        containerConfig = {
          image = cfg.image;
          pull = "missing";
          user = toString cfg.uid;
          group = toString cfg.gid;
          addCapabilities = [
            "CAP_DAC_OVERRIDE"
          ];
          volumes = [
            "${volumes.${cfg.acmeVolumeName}.ref}:/traefik"
            "${cfg.outputDir}:/output"
          ];
        };

        unitConfig = {
          After = traefikContainer.ref;
          BindsTo = traefikContainer.ref;
          ReloadPropagatedFrom = traefikContainer.ref;
        };
      };

      volumes.${cfg.acmeVolumeName} = { };
    };
  };
}
