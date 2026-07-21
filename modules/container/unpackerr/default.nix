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
  inherit (import ../../../lib/container-options.nix { inherit lib; })
    mkImageOption
    networks
    ;
  cfg = config.trev.containers.unpackerr;
  radarr = lib.attrByPath [ "trev" "containers" "radarr" ] { enable = false; } config;
  sonarr = lib.attrByPath [ "trev" "containers" "sonarr" ] { enable = false; } config;
  quadletNetworks = lib.attrByPath [ "virtualisation" "quadlet" "networks" ] { } config;
  radarrNetwork = lib.attrByPath [ "radarr" ] { ref = "radarr"; } quadletNetworks;
  sonarrNetwork = lib.attrByPath [ "sonarr" ] { ref = "sonarr"; } quadletNetworks;
  secretFileType = types.either types.path types.str;
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
    radarrSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/radarr.age;
      description = "Age file containing the Radarr API key.";
    };
    sonarrSecretFile = mkOption {
      type = secretFileType;
      default = self + /secrets/sonarr.age;
      description = "Age file containing the Sonarr API key.";
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

    secrets = {
      radarr.file = cfg.radarrSecretFile;
      sonarr.file = cfg.sonarrSecretFile;
    };

    virtualisation.quadlet.containers.unpackerr.containerConfig = {
      image = cfg.image;
      pull = "missing";
      user = "${toString cfg.uid}:${toString cfg.gid}";
      secrets = [
        "${config.secrets.radarr.env},target=UN_RADARR_0_API_KEY"
        "${config.secrets.sonarr.env},target=UN_SONARR_0_API_KEY"
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
}
