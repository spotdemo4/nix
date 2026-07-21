{
  lib,
  config,
  self,
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
    mkContainer
    mkImageOption
    networks
    secretType
    ;
  cfg = config.trev.containers.unpackerr;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } quadletNetworks;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } quadletNetworks;
in
{
  options.trev.containers.unpackerr = {
    enable = mkEnableOption "Unpackerr container";
    image = mkImageOption "ghcr.io/unpackerr/unpackerr:0.15.2@sha256:89e13608521ece21dd300c39229fd595a55fbf4b8152771af5670a7455b5c747";
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "UID used by Unpackerr.";
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
      description = "GID used by Unpackerr.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Detroit";
      description = "Time zone used by Unpackerr.";
    };
    poolPath = mkOption {
      type = types.str;
      default = "/mnt/pool";
      description = "Host media pool path.";
    };
    radarrUrl = mkOption {
      type = types.str;
      default = "http://radarr:7878";
      description = "Radarr URL used by Unpackerr.";
    };
    sonarrUrl = mkOption {
      type = types.str;
      default = "http://sonarr:8989";
      description = "Sonarr URL used by Unpackerr.";
    };
    radarrSecret = mkOption {
      type = secretType;
      default = {
        ref = "radarr";
        file = self + /secrets/radarr.age;
      };
      description = "Radarr API key secret.";
    };
    sonarrSecret = mkOption {
      type = secretType;
      default = {
        ref = "sonarr";
        file = self + /secrets/sonarr.age;
      };
      description = "Sonarr API key secret.";
    };
    networks = networks // {
      default = [
        radarrNetwork.ref
        sonarrNetwork.ref
      ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = radarr.enable;
        message = "trev.containers.unpackerr requires trev.containers.radarr.enable = true";
      }
      {
        assertion = sonarr.enable;
        message = "trev.containers.unpackerr requires trev.containers.sonarr.enable = true";
      }
    ];

    virtualisation.quadlet = {
      secrets = {
        ${cfg.radarrSecret.ref} = cfg.radarrSecret;
        ${cfg.sonarrSecret.ref} = cfg.sonarrSecret;
      };

      containers.unpackerr.containerConfig = mkContainer {
        image = cfg.image;
        pull = "missing";
        user = "${toString cfg.uid}:${toString cfg.gid}";
        secrets = [
          {
            inherit (cfg.radarrSecret) ref;
            type = "env";
            target = "UN_RADARR_0_API_KEY";
          }
          {
            inherit (cfg.sonarrSecret) ref;
            type = "env";
            target = "UN_SONARR_0_API_KEY";
          }
        ];
        environments = {
          TZ = cfg.timeZone;
          UN_RADARR_0_URL = cfg.radarrUrl;
          UN_SONARR_0_URL = cfg.sonarrUrl;
        };
        volumes = [ "${cfg.poolPath}:/pool" ];
        networks = cfg.networks;
      };
    };
  };
}
